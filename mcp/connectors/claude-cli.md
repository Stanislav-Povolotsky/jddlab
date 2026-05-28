# Claude CLI Connector

Replace `<REPO_PATH>` with the absolute path to this repository.

## Add the server

```shell
claude mcp add jddlab -- python <REPO_PATH>/mcp/server.py
```

## List configured MCP servers

```shell
claude mcp list
```

## Remove the server

```shell
claude mcp remove jddlab
```

If your Claude CLI version uses a different MCP management syntax, run:

```shell
claude mcp --help
```

Use the same stdio command:

```text
python <REPO_PATH>/mcp/server.py
```

