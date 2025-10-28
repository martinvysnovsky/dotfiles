import { tool } from "@opencode-ai/plugin"
import fs from "fs"
import path from "path"
import os from "os"
import { execSync } from "child_process"

const WWW_PATH = path.join(os.homedir(), "www")

/**
 * List all projects in ~/www/ directory
 */
export const list_projects = tool({
	description: "List all projects in ~/www/ directory for reference code access",
	args: {},
	async execute() {
		try {
			if (!fs.existsSync(WWW_PATH)) {
				return `Error: ~/www/ directory does not exist`
			}

			const entries = fs.readdirSync(WWW_PATH, { withFileTypes: true })
			const projects = entries
				.filter((entry) => entry.isDirectory() && !entry.name.startsWith("."))
				.map((entry) => entry.name)
				.sort()

			return `Found ${projects.length} projects in ~/www/:\n\n${projects.map((p) => `  - ${p}`).join("\n")}`
		} catch (error) {
			return `Error listing projects: ${error.message}`
		}
	},
})

/**
 * Read a file from ~/www/ reference projects
 */
export const read_file = tool({
	description:
		"Read a file from ~/www/ reference projects. Provide path relative to ~/www/, e.g., 'myproject/src/index.ts'",
	args: {
		projectPath: tool.schema
			.string()
			.describe("Path relative to ~/www/, e.g., 'myproject/src/index.ts'"),
	},
	async execute(args) {
		try {
			// Normalize and resolve the path
			const requestedPath = path.normalize(args.projectPath)
			const fullPath = path.join(WWW_PATH, requestedPath)

			// Security check: ensure path doesn't escape ~/www/
			const resolvedPath = path.resolve(fullPath)
			if (!resolvedPath.startsWith(path.resolve(WWW_PATH))) {
				return `Error: Access denied - path must be within ~/www/ directory`
			}

			// Check if file exists
			if (!fs.existsSync(resolvedPath)) {
				return `Error: File not found: ${args.projectPath}`
			}

			// Check if it's a file (not directory)
			const stats = fs.statSync(resolvedPath)
			if (!stats.isFile()) {
				return `Error: ${args.projectPath} is not a file`
			}

			// Read the file
			const content = fs.readFileSync(resolvedPath, "utf-8")
			const lines = content.split("\n").length

			return `File: ~/www/${args.projectPath}\nLines: ${lines}\n\n${content}`
		} catch (error) {
			return `Error reading file: ${error.message}`
		}
	},
})

/**
 * Search for files in ~/www/ by glob pattern
 */
export const search_files = tool({
	description:
		"Search for files in ~/www/ by glob pattern. Examples: '**/*.ts' for all TypeScript files, 'project-name/**/*.tsx' for React files in a specific project",
	args: {
		pattern: tool.schema
			.string()
			.describe(
				"Glob pattern relative to ~/www/, e.g., '**/*.ts' or 'project-name/**/*.tsx'",
			),
		maxResults: tool.schema
			.number()
			.optional()
			.describe("Maximum number of results to return (default: 50)"),
	},
	async execute(args) {
		try {
			if (!fs.existsSync(WWW_PATH)) {
				return `Error: ~/www/ directory does not exist`
			}

			const maxResults = args.maxResults || 50
			const pattern = args.pattern

			// Use find command with glob pattern for efficient searching
			// Escape the pattern for shell safety
			const findCmd = `find "${WWW_PATH}" -type f -path "${WWW_PATH}/${pattern}" 2>/dev/null | head -n ${maxResults}`

			try {
				const output = execSync(findCmd, {
					encoding: "utf-8",
					maxBuffer: 10 * 1024 * 1024, // 10MB buffer
				})

				const files = output
					.trim()
					.split("\n")
					.filter((f) => f.length > 0)
					.map((f) => path.relative(WWW_PATH, f))

				if (files.length === 0) {
					return `No files found matching pattern: ${pattern}`
				}

				const resultCount = files.length
				const truncated = resultCount >= maxResults ? ` (limited to ${maxResults})` : ""

				return `Found ${resultCount} file(s) matching '${pattern}'${truncated}:\n\n${files.map((f) => `  - ${f}`).join("\n")}`
			} catch (execError) {
				// If find fails, return empty result
				return `No files found matching pattern: ${pattern}`
			}
		} catch (error) {
			return `Error searching files: ${error.message}`
		}
	},
})

/**
 * List directory structure of a project
 */
export const list_directory = tool({
	description:
		"List directory structure of a project in ~/www/. Provide project name or path relative to ~/www/",
	args: {
		projectPath: tool.schema
			.string()
			.describe("Path relative to ~/www/, e.g., 'myproject' or 'myproject/src'"),
		maxDepth: tool.schema
			.number()
			.optional()
			.describe("Maximum depth to traverse (default: 3)"),
	},
	async execute(args) {
		try {
			// Normalize and resolve the path
			const requestedPath = path.normalize(args.projectPath)
			const fullPath = path.join(WWW_PATH, requestedPath)
			const maxDepth = args.maxDepth || 3

			// Security check: ensure path doesn't escape ~/www/
			const resolvedPath = path.resolve(fullPath)
			if (!resolvedPath.startsWith(path.resolve(WWW_PATH))) {
				return `Error: Access denied - path must be within ~/www/ directory`
			}

			// Check if directory exists
			if (!fs.existsSync(resolvedPath)) {
				return `Error: Directory not found: ${args.projectPath}`
			}

			// Check if it's a directory
			const stats = fs.statSync(resolvedPath)
			if (!stats.isDirectory()) {
				return `Error: ${args.projectPath} is not a directory`
			}

			// Use tree command if available, otherwise use find
			let output: string
			try {
				output = execSync(
					`tree -L ${maxDepth} -a -I '.git|node_modules|.next|dist|build|coverage' "${resolvedPath}"`,
					{
						encoding: "utf-8",
						maxBuffer: 5 * 1024 * 1024, // 5MB buffer
					},
				)
			} catch {
				// Fallback to find if tree is not available
				output = execSync(
					`find "${resolvedPath}" -maxdepth ${maxDepth} -not -path '*/.*' -not -path '*/node_modules/*' | sort`,
					{
						encoding: "utf-8",
						maxBuffer: 5 * 1024 * 1024,
					},
				)
				output = output
					.split("\n")
					.map((f) => path.relative(resolvedPath, f))
					.join("\n")
			}

			return `Directory structure of ~/www/${args.projectPath}:\n\n${output}`
		} catch (error) {
			return `Error listing directory: ${error.message}`
		}
	},
})
