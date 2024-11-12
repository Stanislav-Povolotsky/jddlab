import ghidra.app.decompiler.*;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.IOException;

public class CustomDecompileScript extends GhidraScript {
    @Override
    public void run() throws Exception {
        if (getScriptArgs().length < 1) {
            println("Error: No output file specified.");
            return;
        }

        String outputFilePath = getScriptArgs()[0];

        DecompInterface decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        
        try (PrintWriter writer = new PrintWriter(new FileWriter(outputFilePath))) {
            writer.println(String.format("// jddlab decompiled binary '%s' with ghidra", currentProgram));

            Listing listing = currentProgram.getListing();
            for (Function function : listing.getFunctions(true)) {
                try {
                    DecompileResults res = decomp.decompileFunction(function, 30, monitor);
                    if (res != null && res.decompileCompleted()) {
                        writer.println("// Decompiled Function: " + function.getName());
                        writer.println(res.getDecompiledFunction().getC());
                        writer.println();
                    }
                } catch (Exception ex) {
                    writer.println(String.format("// Error decompiling function %s: %s", function.getName(), ex));
                }
            }
            println("Decompilation completed. Output written to: " + outputFilePath);
        } catch (IOException e) {
            println("Error writing to file: " + e.getMessage());
            throw e;
        } finally {
            decomp.dispose();
        }
    }
}
