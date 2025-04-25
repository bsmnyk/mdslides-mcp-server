import subprocess
import os
import tempfile
import json
import yaml
import logging
from typing import Optional, Dict, Any

from mcp.server.fastmcp import FastMCP

# Configure logging
logging.basicConfig(level=logging.INFO, format='[%(levelname)s] %(message)s')
logger = logging.getLogger(__name__)

# Create an MCP server instance
mcp = FastMCP("MkSlides Server", dependencies=["mkslides"])


@mcp.tool()
def generate_slides(
    markdown_content: str,  # Now required, not Optional
    output_dir: str = "./mkslides_output",
    config_json: Optional[Dict[str, Any]] = None,  # New parameter
    slides_theme: Optional[str] = None,
    slides_highlight_theme: Optional[str] = None,
    revealjs_options: Optional[Dict[str, Any]] = None,
    strict: bool = False,
) -> str:
    """
    Generates HTML presentation slides from Markdown content using the mkslides library.

    This tool converts raw Markdown text into a complete HTML presentation using the
    mkslides build system, which is powered by Reveal.js. The generated slides are
    saved to the specified output directory.

    Args:
        markdown_content (str): Required. Raw Markdown text for the slides. Must include
            valid mkslides markdown syntax with slide separators (---).
        output_dir (str, optional): Directory path where the generated HTML slides will be saved.
            Defaults to "./mkslides_output". The directory will be created if it doesn't exist.
        config_json (Dict[str, Any], optional): Complete mkslides configuration as a JSON object.
            If provided, this overrides the individual config options (slides_theme,
            slides_highlight_theme, revealjs_options). Use this for advanced configuration.
        slides_theme (str, optional): Theme name for the slides. This overrides the default
            theme in mkslides. Common values include "black", "white", "league", etc.
            Only applied if config_json doesn't contain a 'slides.theme' setting.
        slides_highlight_theme (str, optional): Syntax highlighting theme for code blocks.
            Only applied if config_json doesn't contain a 'slides.highlight_theme' setting.
        revealjs_options (Dict[str, Any], optional): Dictionary of Reveal.js configuration options
            to merge with or override the default settings. See Reveal.js documentation for
            available options. Only applied if config_json doesn't contain 'revealjs' settings.
        strict (bool, optional): When True, enables strict mode for mkslides build process,
            which will fail on warnings. Defaults to False.

    Returns:
        str: Absolute path to the output directory containing the generated HTML slides.
            The main presentation file will be named 'index.html' within this directory.

    Raises:
        ValueError: If markdown_content is empty or not provided.
        RuntimeError: If the mkslides build command fails. This could happen if:
            - The mkslides command is not installed or not in PATH
            - The markdown content contains syntax errors
            - There are issues with the configuration options
            - The output directory cannot be created or written to

Examples:
    Basic usage with minimal options:
    ```python
    output_path = generate_slides(
        markdown_content="# My Presentation\n\n---\n\n## Slide 2\n\nContent"
    )
    ```

    Using a custom theme and output directory:
    ```python
    output_path = generate_slides(
        markdown_content="# Themed Presentation\n\n---\n\n## Content",
        output_dir="./custom_slides",
        slides_theme="black"
    )
    ```

    Advanced configuration with Reveal.js options:
    ```python
    output_path = generate_slides(
        markdown_content="# Advanced Presentation\n\n---\n\n## Content",
        revealjs_options={
            "transition": "slide",
            "controls": True,
            "progress": True
        }
    )
    ```

Notes:
    - The function creates temporary files for the markdown content and configuration,
      which are automatically cleaned up after execution.
    - All operations are logged with appropriate log levels for debugging.
    - The generated slides can be viewed by opening the index.html file in a web browser.
"""
    if not markdown_content:
        logger.error("[Error] markdown_content was not provided.")
        raise ValueError("markdown_content must be provided.")

    # Create a temporary markdown file
    temp_md_file = tempfile.NamedTemporaryFile(mode='w+', suffix=".md", delete=False)
    temp_md_file.write(markdown_content)
    temp_md_file.close()
    input_path = temp_md_file.name
    logger.info(f"[Setup] Created temporary markdown file: {input_path}")

    temp_config_file = None
    config_arg = []

    # Handle configuration
    if config_json or slides_theme or slides_highlight_theme or revealjs_options:
        # Start with config_json if provided, otherwise empty dict
        config = config_json.copy() if config_json else {}
        
        # Only apply individual overrides if config_json doesn't already have these sections
        if not config_json or 'slides' not in config_json:
            if 'slides' not in config:
                config['slides'] = {}
            if slides_theme:
                config['slides']['theme'] = slides_theme
                logger.info(f"[Setup] Setting slides theme: {slides_theme}")
            if slides_highlight_theme:
                config['slides']['highlight_theme'] = slides_highlight_theme
                logger.info(f"[Setup] Setting slides highlight theme: {slides_highlight_theme}")

        if not config_json or 'revealjs' not in config_json:
            if 'revealjs' not in config:
                config['revealjs'] = {}
            if revealjs_options:
                # Merge revealjs_options
                config['revealjs'].update(revealjs_options)
                logger.info(f"[Setup] Setting Reveal.js options: {revealjs_options}")

        # Create a temporary config file
        temp_config_file = tempfile.NamedTemporaryFile(mode='w+', suffix=".yml", delete=False)
        yaml.dump(config, temp_config_file)
        temp_config_file.close()
        config_arg = ["-f", temp_config_file.name]
        logger.info(f"[Setup] Created temporary config file: {temp_config_file.name}")
        logger.info(f"[Setup] Config content: {json.dumps(config, indent=2)}")

    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    logger.info(f"[Setup] Ensuring output directory exists: {output_dir}")

    # Build the mkslides command
    command = ["mkslides", "build", input_path, "-d", output_dir] + config_arg
    if strict:
        command.append("-s")

    logger.info(f"[API] Executing mkslides build command: {' '.join(command)}")

    try:
        # Execute the command
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        logger.info(f"[API] mkslides build stdout:\n{result.stdout}")
        if result.stderr:
             logger.warning(f"[API] mkslides build stderr:\n{result.stderr}")

        logger.info(f"[API] mkslides build completed successfully.")

    except subprocess.CalledProcessError as e:
        logger.error(f"[Error] mkslides build failed with exit code {e.returncode}")
        logger.error(f"[Error] stdout:\n{e.stdout}")
        logger.error(f"[Error] stderr:\n{e.stderr}")
        raise RuntimeError(f"mkslides build failed: {e.stderr}")
    except FileNotFoundError:
         logger.error("[Error] 'mkslides' command not found. Is it installed and in the PATH?")
         raise RuntimeError("'mkslides' command not found. Is it installed and in the PATH?")
    except Exception as e:
        logger.error(f"[Error] An unexpected error occurred during mkslides build: {e}")
        raise RuntimeError(f"An unexpected error occurred during mkslides build: {e}")
    finally:
        # Clean up temporary files
        if temp_md_file and os.path.exists(temp_md_file.name):
            os.remove(temp_md_file.name)
            logger.info(f"[Setup] Cleaned up temporary markdown file: {temp_md_file.name}")
        if temp_config_file and os.path.exists(temp_config_file.name):
            os.remove(temp_config_file.name)
            logger.info(f"[Setup] Cleaned up temporary config file: {temp_config_file.name}")

    return os.path.abspath(output_dir)

if __name__ == "__main__":
    mcp.run()
