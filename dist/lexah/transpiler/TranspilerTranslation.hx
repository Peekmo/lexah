// vim: set ft=rb:
package lexah.transpiler;

import lexah.tools.StringHandle;
import sys.io.File;

using Lambda;
using StringTools;

class TranspilerTranslation{

private var script: Bool = false;
private var path: String = "";
private var name: String = "";
private var currentType: String = "";
private var opened: Int = 0;
private var tokens: Array<String> = [
    // Line break
    "\n",

    // Inheritance & interfaces
    "<", "::",

    // Comments
    "--*", "*--", "--",

    // Lexah keywords
    "-", "require", "def", ".new", "self.", "self", "end", "do", "puts", "raise", "begin", "rescue", "const", "module", "var",

    // Standard keywords
    "![", "]", "@{", "}", "\\",  "\"", "\\\"", "(", ")", "/", "=", "$", ",", "@:", "@", ":", "*", "{", "}", ".", ";", "?", "[", "]",

    // Expressions
    "elsif", "if", "else", "while", "for", "then", "and", "or",

    // Types
    "class", "enum", "abstract", "interface",

    // Modifiers
    "private", "public",
];

/**
    Transpile the given file from the given directory
**/
public function transpile(directory: String, file: String): String{
    var currentPackage = StringTools.replace(file, directory, "");
    currentPackage = StringTools.replace(currentPackage, "\\", "/");

    var currentModule = StringTools.replace(currentPackage.substr(currentPackage.lastIndexOf("/") + 1), ".lxa", "");
    currentPackage = StringTools.replace(currentPackage, currentPackage.substr(currentPackage.lastIndexOf("/")), "");
    currentPackage = StringTools.replace(currentPackage, "/", ".");

    content = File.getContent(file);

    this.name = currentModule;
    this.path = currentPackage;

    return this.run( new StringHandle(content, this.tokens));
}

/**
    Process transpile
**/
private function run(handle: StringHandle): String{
    return "";
}

private function safe_next_token(handle: StringHandle) Bool{
    handle.nextToken();

    if( this.safe_check(handle, "def") && this.safe_check(handle, "if") && this.safe_check(handle, "elsif")
    && this.safe_check(handle, "end") && this.safe_check(handle, "self") && this.safe_check(handle, "while")
    && this.safe_check(handle, "for") && this.safe_check(handle, "next") && this.safe_check(handle, "do")
    && this.safe_check(handle, "else") && this.safe_check(handle, "require") ) {
        return true;
    }

    handle.increment();
    return this.safe_next_token(handle));
}

private function safe_check(handle: StringHandle, content: String): Bool{
    if( handle.is(content)
        return handle.safeis(content)
    end

    return true
end
) {
}