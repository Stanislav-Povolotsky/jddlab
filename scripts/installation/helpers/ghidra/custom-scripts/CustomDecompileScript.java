import ghidra.app.decompiler.*;
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.*;
import ghidra.program.model.data.*;
import ghidra.program.model.address.*;
import ghidra.program.model.mem.MemoryAccessException;
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

            // Global Variables
            SymbolTable symTable = currentProgram.getSymbolTable();
            writer.println("\n// Global Variables");
            for (Symbol symbol : symTable.getAllSymbols(false)) {
                if ((symbol.getSymbolType() == SymbolType.GLOBAL || symbol.getSymbolType() == SymbolType.LABEL) && symbol.getAddress().isMemoryAddress()) {
                    Data data = getDataAt(symbol.getAddress());
                    if (data != null) {
                        writer.println(formatData(symbol.getName(), data));
                    }
                }
            }
            
            // Decompiled Functions
            writer.println("\n// Decompiled Functions");
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
    
    private String formatData(String name, Data data) {
        DataType dataType = data.getDataType();
        String type = mapDataType(dataType);
        String value = data.getDefaultValueRepresentation();
        //print(name + " have class " + dataType.getClass().getName());

        try {
            // See classes at https://ghidra.re/ghidra_docs/api/ghidra/program/model/data/DataType.html
            if (dataType instanceof LongDataType || dataType instanceof SignedQWordDataType) {
                long longValue = (long)data.getLong(0);
                type = "int64_t"; 
                value = formatLongValue(longValue, false);
            } else if (dataType instanceof IntegerDataType || dataType instanceof SignedDWordDataType) {
                int intValue = (int)data.getInt(0);
                type = "int32_t"; 
                value = formatLongValue((long)intValue & 0xFFFFFFFFL, false);
            } else if (dataType instanceof ShortDataType || dataType instanceof SignedWordDataType) {
                short shortValue = (short)data.getShort(0);
                type = "int16_t"; 
                value = formatLongValue((long)shortValue & 0xFFFFL, false);
            } else if (dataType instanceof SignedByteDataType) {
                byte byteValue = (byte)data.getByte(0);
                type = "int8_t"; 
                value = formatLongValue((long)byteValue & 0xFFL, false);
            } else if (dataType instanceof UnsignedLongDataType || dataType instanceof DWordDataType || dataType instanceof Undefined8DataType) {
                long longValue = (long)data.getLong(0);
                type = "uint64_t"; 
                value = formatLongValue(longValue, true);
            } else if (dataType instanceof UnsignedIntegerDataType || dataType instanceof DWordDataType || dataType instanceof Undefined4DataType) {
                long intValue = (long)data.getUnsignedInt(0);
                type = "uint32_t"; 
                value = formatLongValue((long)intValue & 0xFFFFFFFFL, true);
            } else if (dataType instanceof UnsignedShortDataType || dataType instanceof WordDataType || dataType instanceof Undefined2DataType) {
                long shortValue = (long)data.getUnsignedShort(0);
                type = "uint16_t"; 
                value = formatLongValue((long)shortValue & 0xFFFFL, true);
            } else if (dataType instanceof UnsignedCharDataType || dataType instanceof ByteDataType || dataType instanceof Undefined1DataType) {
                long byteValue = (long)data.getUnsignedByte(0);
                type = "uint8_t"; 
                value = formatLongValue((long)byteValue & 0xFFL, true);
            } else if (dataType instanceof FloatDataType) {
                float floatValue = (float) data.getValue();
                value = String.format("%f", floatValue, false);
            } else if (dataType instanceof DoubleDataType) {
                double doubleValue = (double) data.getValue();
                value = String.format("%f", doubleValue, false);
            } else if (dataType instanceof StringDataType) {
                //String stringValue = (String) data.getValue();
            } else if (dataType instanceof CharDataType) {
                //char charValue = (char) data.getValue();
            } else if (dataType instanceof StringUTF8DataType) {
                // Nothing to do
                type = "char";
                name = removeArrayWithLengthSuffix(name) + "[]";
            } else if (dataType instanceof PointerDataType || dataType instanceof Pointer) {
                //long pointerValue = (long) data.getValue();
                // Nothing to do
            }/* else if (dataType instanceof EnumDataType) {
                // ToDO
                int enumValue = (int) data.getValue();
                System.out.println("Enum value: " + enumValue);
            }*/ else if (dataType instanceof ArrayDataType || dataType instanceof ArrayStringable || dataType instanceof Array) {
                type = "char";
                value = convertToCharArray(data);
            } else {
                println("Unsupported type for '" + name + "': " + dataType.getClass().getName());
                value = formatHexValue(data);
            }

        } catch (Exception e) {
            println("Error accessing data value: " + e.getMessage());
        }
                
        return String.format("%s %s = %s;", type, name, value);
    }

    private static String removeArrayWithLengthSuffix(String input) {
        if (input != null && input.matches(".*\\[\\d+\\]$")) {
            return input.replaceAll("\\[\\d+\\]$", "");
        }
        return input;
    }
    
    private String mapDataType(DataType dataType) {
        if (dataType instanceof Array) {
            Array arrayType = (Array) dataType;
            return "char[" + arrayType.getLength() + "]";
        }
        switch (dataType.getDisplayName()) {
            case "undefined8": return "uint64_t";
            case "undefined4": return "uint32_t";
            case "undefined2": return "uint16_t";
            case "undefined1": return "uint8_t";
            case "dword": return "uint32_t";
            case "word": return "uint16_t";
            case "byte": return "uint8_t";
            case "int8": return "int64_t";
            case "int4": return "int32_t";
            case "int2": return "int16_t";
            case "int1": return "int8_t";
            default: return dataType.getDisplayName();
        }
    }

    private String formatLongValue(long data, boolean unsigned) {
        if (data < 100 && !unsigned) {
            return String.format("%d", data);
        }
        return "0x" + String.format("%X", data);
    }
    
    private String formatHexValue(Data data) {
        try {
            return "0x" + String.format("%X", data.getInt(0));
        } catch (MemoryAccessException e) {
            return "0x??";
        }
    }
    
    private String convertToCharArray(Data data) {
        int length = (int) data.getLength();
        StringBuilder sb = new StringBuilder("{");
        for (int i = 0; i < length; i++) {
            try {
                sb.append("0x").append(String.format("%02X", data.getByte(i) & 0xFF));
            } catch (MemoryAccessException e) {
                sb.append("0x??");
            }
            if (i < length - 1) {
                sb.append(", ");
            }
        }
        sb.append("}");
        return sb.toString();
    }
}
