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
    "##*", "*##", "##",

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
            count--
        }

        handle.increment();
        if( count == 0 ) {
            break;
        }
    }
}

/**
    Consume a condition (if, elsif, while, for)
**/
private function consume_condition(handle: StringHandle, token: String){
    handle.insert("(");

    while( handle.nextToken() ) {
        if( handle.safeis(token) ) {
            handle.remove();
            break;
        }else if( handle.safeis("and") ) {
            handle.remove();
            handle.insert("&&");
        }else if( handle.safeis("or") ) {
            handle.remove();
            handle.insert("||");
        }else if( handle.is("@") ) {
            this.check_this(handle);
        }
        
        handle.increment();
    }

    handle.insert(") {");
    handle.increment(") {");
    this.opened++;
}

/**
    Search for "@" as "this"
**/
private function check_this(handle: StringHandle){
    var position = handle.position;
    handle.nexToken();

    if( handle.position != position + 1 ) {
        handle.position = position;
        handle.remove();
        handle.insert("this.");
        handle.increment();
    }
}

}