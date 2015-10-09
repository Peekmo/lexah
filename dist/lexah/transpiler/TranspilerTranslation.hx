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

/**
    Consume curlies (functions)
**/
private function consume_curlies(handle: StringHandle){
    var count = 0;

    while( hande.nextToken() ) {
        if( handle.is("(") ) {
            count++;
        }else if( handle.is(")") ) {
            count = count - 1;
        }

        handle.increment();
        if( count == 0 ) {
            break;
        }
    }
}

}