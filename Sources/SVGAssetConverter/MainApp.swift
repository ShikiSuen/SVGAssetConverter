import Foundation

@main
struct SVGAssetConverter {
  @MainActor
  static func main() {
    do {
      let arguments = Array(CommandLine.arguments.dropFirst())
      if arguments.contains(where: { $0 == "--help" || $0 == "-h" }) {
        printUsage()
        return
      }
      let outputDirectory = try resolveOutputDirectory(from: arguments)
      print("Rendering \(SVGIconAsset.allCases.count) SVG icons to \(outputDirectory.path)...")
      let outputs = try SVGIconExporter.exportAll(to: outputDirectory)
      outputs.forEach { print("✅ \($0.lastPathComponent)") }
    } catch {
      fputs("❌ SVG export failed: \(error.localizedDescription)\n", stderr)
      exit(EXIT_FAILURE)
    }
  }

  // MARK: Private

  private static func resolveOutputDirectory(from arguments: [String]) throws -> URL {
    guard let flagIndex = arguments.firstIndex(where: { $0 == "--output" || $0 == "-o" }) else {
      return URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
    }
    let valueIndex = arguments.index(after: flagIndex)
    guard valueIndex < arguments.endIndex else {
      throw CLIError.missingOutputValue
    }
    let providedPath = (arguments[valueIndex] as NSString).expandingTildeInPath
    return URL(fileURLWithPath: providedPath, isDirectory: true)
  }

  private static func printUsage() {
    let executable = (CommandLine.arguments.first as NSString?)?.lastPathComponent ?? "SVGAssetConverter"
    print("""
    Usage: \(executable) [--output <directory>]

    Options:
      -o, --output    Directory where 96x96 template PNGs will be written. Defaults to the current working directory.
      -h, --help      Show this help information.
    """)
  }
}

enum CLIError: LocalizedError {
  case missingOutputValue

  var errorDescription: String? {
    switch self {
    case .missingOutputValue:
      return "--output expects a directory path."
    }
  }
}
