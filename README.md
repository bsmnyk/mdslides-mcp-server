# mdslides-mcp-server

An MCP (Model Context Protocol) server for generating HTML slides from Markdown content using the [mkslides](https://github.com/saoudrizwan/mkslides) library.

## What it Does

This server provides a simple interface to the `mkslides` command-line tool, allowing you to generate presentation slides directly from Markdown input via the Model Context Protocol. This enables integration with tools like Claude in VSCode to easily create and manage presentations.

## Demo
[mcp-demo.webm](https://github.com/user-attachments/assets/7a541e5e-2509-4a16-a007-f423dc65df05)

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
    git clone https://github.com/your-repo/mdslides-mcp-server.git
    cd mdslides-mcp-server
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

1.  Ensure Docker is installed and running.
2.  From the repository root, run the deployment script:
    ```bash
./deploy_mdslides_docker.sh
```
This script will build the Docker image (if not already built) and start a container instance named `mdslides-mcp-instance`. The server inside the container will be running and ready to accept connections via MCP. The script also handles creating the necessary output directory (`./mkslides_output`) on the host.

### Configuration in MCP Settings

To use the server with your MCP client (like Claude in VSCode), you need to add it to your MCP settings.

If you installed using pip, you can run the server directly:

```json
{
  "mcpServers": {
    "mdslides-mcp-local": {
      "command": "python",
      "args": ["src/mdslides_mcp_server/server.py"],
      "disabled": false,
      "autoApprove": []
    }
  }
}
```

If you are using the Docker deployment via the script:

Configure your MCP client to attach to the running container instance:

```json
{
  "mcpServers": {
    "mdslides-mcp-local": {
      "autoApprove": [],
      "disabled": false,
      "timeout": 60,
      "command": "docker",
      "args": [
        "attach",
        "mdslides-mcp-instance"
      ],
      "transportType": "stdio"
    }
  }
}
```

## Usage with Claude/VSCode

Once configured in your MCP settings, you can use the `generate_slides` tool directly within your Claude chat interface in VSCode.

### Available Tool: `generate_slides`

Generates HTML presentation slides from Markdown input using mkslides and serves them via a local HTTP server.

**Parameters:**

*   `markdown_content` (string, **required**): Raw Markdown text for the slides.
*   `slides_theme` (string, optional): Theme name for the slides (e.g., `black`, `white`, `league`, `beige`, `night`, `serif`, `simple`, `solarized`, `moon`, `dracula`, `sky`, `blood`). Overrides the default.
*   `slides_highlight_theme` (string, optional): Syntax highlighting theme for code blocks (any built-in theme from `highlight.js`).
*   `revealjs_options` (object, optional): A dictionary containing Reveal.js config options to merge/override defaults.

**Returns:**

*   (string): A URL (e.g., `http://localhost:8080/latest/index.html`) pointing to the generated HTML slides served by the MCP server's internal HTTP server. You can open this URL in your browser.

**Example Usage:**

```xml
<use_mcp_tool>
<server_name>mdslides-mcp-local</server_name>
<tool_name>generate_slides</tool_name>
<arguments>
{
  "markdown_content": "# My Presentation\n\n---\n\n## Slide 2\n\n- Bullet 1\n- Bullet 2",
  "slides_theme": "black",
  "revealjs_options": {
    "transition": "slide"
  }
}
</arguments>
</use_mcp_tool>
```

This will generate the slides in the default output directory (`./mkslides_output`) using the 'black' theme and a 'slide' transition.

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
