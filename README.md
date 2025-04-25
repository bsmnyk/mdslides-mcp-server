# mkslides-mcp-server

An MCP (Model Context Protocol) server for generating HTML slides from Markdown content using the [mkslides](https://github.com/saoudrizwan/mkslides) library.

## What it Does

This server provides a simple interface to the `mkslides` command-line tool, allowing you to generate presentation slides directly from Markdown input via the Model Context Protocol. This enables integration with tools like Claude in VSCode to easily create and manage presentations.

## Features

*   Generate HTML slides from Markdown.
*   Support for various mkslides configuration options (themes, highlight themes, Reveal.js options).
*   Clean handling of temporary files.
*   Containerized deployment option using Docker.

## Installation

### Prerequisites

*   Python 3.12 or higher
*   [mkslides](https://github.com/saoudrizwan/mkslides) installed and available in your PATH.
*   [Model Context Protocol (MCP)](https://github.com/modelcontextprotocol/mcp) client (e.g., Claude in VSCode).
*   Docker (if using the Docker installation method).

### Installation Methods

#### Using pip

1.  Clone the repository:
    ```bash
    git clone https://github.com/your-repo/mkslides-mcp-server.git # Replace with actual repo URL
    cd mkslides-mcp-server
    ```
2.  Install using pip and uv (recommended):
    ```bash
    uv sync
    ```
    Or using pip:
    ```bash
    pip install .
    ```

#### Using Docker

1.  Build the Docker image from the repository root:
    ```bash
    docker build -t mkslides-mcp-server:latest .
    ```

### Configuration in MCP Settings

To use the server with your MCP client (like Claude in VSCode), you need to add it to your MCP settings.

If you installed using pip, you can run the server directly:

```json
{
  "mcpServers": {
    "mkslides-mcp-local": {
      "command": "python",
      "args": ["src/mkslides_mcp_server/server.py"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

If you built the Docker image, you can configure it to run the container:

```json
{
  "mcpServers": {
    "mkslides-mcp-local": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-v",
        "/path/to/your/output:/app/mkslides_output", // IMPORTANT: Replace with your desired output path
        "mkslides-mkslides-server:latest"
      ],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```
**Note:** Ensure the volume mount path (`/path/to/your/output`) is correctly set to a directory on your host machine where you want the generated slides to be saved. The server will save files to `/app/mkslides_output` inside the container, which is mapped to your host path.

## Usage with Claude/VSCode

Once configured in your MCP settings, you can use the `generate_slides` tool directly within your Claude chat interface in VSCode.

### Available Tool: `generate_slides`

Generates HTML slides from Markdown input using mkslides.

**Parameters:**

*   `markdown_content` (string, **required**): Raw Markdown text for the slides.
*   `output_dir` (string, optional, default: `./mkslides_output`): Directory to save the generated HTML slide(s). This path is relative to the server's working directory (or the mounted volume inside the Docker container).
*   `config_json` (object, optional): Complete configuration as a JSON object. This overrides other individual config options (`slides_theme`, `slides_highlight_theme`, `revealjs_options`).
*   `slides_theme` (string, optional): Override the `slides.theme` setting from the mkslides configuration.
*   `slides_highlight_theme` (string, optional): Override the `slides.highlight_theme` setting from the mkslides configuration.
*   `revealjs_options` (object, optional): A dictionary containing Reveal.js config options to merge/override the `revealjs` section of the mkslides configuration.
*   `strict` (boolean, optional, default: `false`): Corresponds to the `--strict` flag in `mkslides build`.

**Example Usage:**

```xml
<use_mcp_tool>
<server_name>mkslides-mcp-local</server_name>
<tool_name>generate_slides</tool_name>
<arguments>
{
  "markdown_content": "# My Presentation\n\n---\n\n## Slide 2\n\n- Bullet 1\n- Bullet 2",
  "output_dir": "./my_slides",
  "slides_theme": "black",
  "revealjs_options": {
    "transition": "slide"
  }
}
</arguments>
</use_mcp_tool>
```

This will generate the slides in the `./my_slides` directory (relative to the server's output directory) using the 'black' theme and a 'slide' transition.

## Development

### Contributing

Contributions are welcome! Please follow standard GitHub practices: fork the repository, create a feature branch, and submit a pull request.

### Running Tests

Currently, there is a placeholder test file (`tests/test_server.py`). To run tests, you would typically use a test runner like `pytest`:

```bash
pytest
```
Remember to add actual tests to `tests/test_server.py`.

### Building from Source

Follow the pip installation steps above to set up your development environment.

## License

This project is licensed under the MIT License - see the LICENSE file for details. (Note: A LICENSE file does not currently exist in the repository. You may want to create one.)

## Acknowledgements

*   [mkslides](https://github.com/saoudrizwan/mkslides) for the core slide generation functionality.
*   [Model Context Protocol](https://github.com/modelcontextprotocol/mcp) for enabling server integration.
