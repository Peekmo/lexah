// vim: set ft=rb:
package lexah.transpiler;

import lexah.tools.StringHandle;
import sys.io.File;

using Lambda;
using StringTools;

class Transpiler{

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
    "-", "require", "def", ".new(", "self.", "self", "end", "do", "puts", "raise", "begin", "rescue", "const", "module", "var",

    // Standard keywords
    "![", "]", "@{", "}", "\\",  "\"", "\\\"", "(", ")", "/", "=", "#", ",", "@:", "@", ":", "*", "{", "}", ".",
    ";", "?", "[", "<", ">",

    // Expressions
    "elsif", "if", "else", "while", "for", "then", "and", "or",

    // Types
    "class", "enum", "abstract", "interface",

    // Modifiers
    "private", "public",
];

public function new(){

}

/**
    Transpile the given file from the given directory
**/
public function transpile(directory: String, file: String): String{
    var currentPackage = StringTools.replace(file, directory, "");
    currentPackage = StringTools.replace(currentPackage, "\\", "/");
    var currentModule = StringTools.replace(currentPackage.substr(currentPackage.lastIndexOf("/") + 1), ".lxa", "");
    currentPackage = StringTools.replace(currentPackage, currentPackage.substr(currentPackage.lastIndexOf("/")), "");
    currentPackage = StringTools.replace(currentPackage, "/", ".");

    if( currentPackage.charAt(0) == "." ) {
        currentPackage = currentPackage.substr(1);
    }

    var content = File.getContent(file);

    this.name = currentModule;
    this.path = currentPackage;

    return this.run( new StringHandle(content, this.tokens));
}

/**
    Process transpile
**/
private function run(handle: StringHandle): String{
    var is_fixed = false;
    var fully_fixed = false;

    while( handle.nextToken() ) {
        // Multiline Comment
        if( handle.is("##*") ) {
            handle.remove();
            handle.insert("/**");

            while( handle.nextToken() ) {
                if( handle.is("*##") ) {
                    handle.remove();
                    handle.insert("**/");
                    handle.increment();
                    break;
                }

                handle.increment();
            }

        // Single line comment
        }else if( handle.is("##") ) {
            handle.remove();
            handle.insert("//");
            handle.increment();
            handle.next("\n");
            handle.increment();

        // Invoke pure haxe code
        }else if( handle.is("@{") ) {
          handle.remove();
          handle.next("}");
          handle.remove();
          handle.increment();

        // Constants
        }else if( handle.is("const") ) {
            handle.remove();
            handle.insert("public static inline var");
            handle.increment();

        // Modifiers on the function/var (private, dynamic, ...)
        }else if( handle.is("![") ) {
            handle.remove();
            var startPosition = handle.position;
            handle.increment();

            handle.next("]");
            var finalPosition = handle.position;
            handle.position = startPosition;
            var comas = 0;

            while( true ) {
                if( !handle.next(",") && handle.position < finalPosition ) {
                    handle.next("]");
                    handle.remove();
                    handle.nextToken();
                    break;
                }

                if( handle.position > finalPosition ) {
                    handle.position = finalPosition - comas;

                    // If some "," removed
                    if( comas != 0 ) {
                        handle.prev("]");
                    }

                    handle.remove();
                    handle.nextToken();
                    break;
                }

                comas++;
                handle.remove();
            }

            if( handle.is("\n") ) {
                handle.remove();
                handle.insert(" ");
                handle.increment();
            }

        // Compiler defines
        }else if( handle.is("#") ) {
            handle.next("\n");

        // this.
        }else if( handle.is("@") ) {
            this.check_this(handle);

        // String
        }else if( handle.is("\"") ) {
            this.process_string(handle);

        // Instanciate object
        }else if( handle.is(".new(") ) {
            handle.remove();
            handle.insert("(");
            handle.prevTokenLine();

            while( true ) {
                if( handle.is(">") ) {
                    handle.prev("<");
                    handle.decrement();
                    handle.prevTokenLine();
                }else if( !handle.isOne(["=", ":", "\n", ".", "(", "[", ";", ","]) ) {
                    handle.prevTokenLine();
                }else{
                    break;
                }
            }

            handle.increment();
            handle.insert(" new ");
            handle.increment();

        // trace()
        }else if( handle.safeis("puts") ) {
            handle.remove();
            handle.insert("trace");
            handle.increment();

        // try {}
        }else if( handle.safeis("begin") ) {
            handle.remove();
            handle.insert("try {");
            handle.increment();

        // throw
        }else if( handle.safeis("raise") ) {
            handle.remove();
            handle.insert("throw");
            handle.increment();

        // catch() {}
        }else if( handle.safeis("rescue") ) {
            handle.remove();
            handle.insert("} catch");
            handle.increment();
            handle.insert("(");
            handle.next("\n");
            handle.insert("){");
            handle.increment();

        // }
        }else if( handle.safeis("end") ) {
            handle.remove();
            handle.insert("}");
            this.opened--;
            handle.increment();

        // module = package
        }else if( handle.is_word("module") ) {
            handle.remove();
            handle.insert("package");
            handle.increment();
            handle.next("\n");

        // require = import
        }else if( handle.safeis("require") ) {
            handle.remove();
            handle.insert("import");
            handle.increment();

            var first_quote = true;

            while( handle.nextToken() ) {
                if( handle.is("\"") ) {
                    handle.remove();

                    if( (!first_quote) ) {
                        handle.insert(";");
                        handle.increment();
                        handle.increment();
                        break;
                    }

                    first_quote = false;
                }else if( handle.is("/") ) {
                    handle.remove();
                    handle.insert(".");
                }

                handle.increment();
            }

        // Function
        }else if( handle.safeis("def") ) {
            this.check_visibility(handle, "def");

            handle.insert("function");
            handle.next("\n");

            if( (this.currentType == "class") ) {
                handle.insert("{");
            }else if( (this.currentType == "interface") ) {
                handle.insert(";");
            }

            handle.increment();
            this.opened++;

        // Variable
        }else if( handle.safeis("var") ) {
            this.check_visibility(handle, "var");

            handle.insert("var");
            handle.increment();

        // Anonymous
        }else if( handle.safeis("do") ) {
            handle.remove();
            handle.insert("function");
            handle.increment();
            this.consume_curlies(handle);
            handle.insert("{");
            handle.increment();
            this.opened++;

        // elsif
        }else if( handle.safeis("elsif") ) {
            handle.remove();
            handle.insert("}else if");
            handle.increment();
            this.opened--;
            this.consume_condition(handle, "then");

        // Loops
        }else if( handle.safeis("while") || handle.safeis("for") ) {
            handle.increment();
            this.consume_condition(handle, "do");

        // next = continue
        }else if( handle.safeis("next") ) {
            handle.remove();
            handle.insert("continue");
            handle.increment();

        // Condition "if"
        }else if( handle.safeis("if") ) {
            handle.increment();
            this.consume_condition(handle, "then");

        // Condition "else"
        }else if( handle.safeis("else") ) {
            handle.insert("}");
            handle.increment();
            handle.increment("else");
            handle.insert("{");
            handle.increment();

        // [abstract] class/interface/enum
        }else if( handle.safeis("class") || handle.safeis("interface") || handle.safeis("enum") ) {
          this.currentType = handle.current;
          handle.remove();
          handle.insert("using Lambda;\nusing StringTools;\n\n").increment();
          handle.insert(this.currentType);

          handle.increment();

          while( handle.nextToken() ) {
            if( (handle.is("self")) ) {
              handle.remove();
              handle.insert(name);
            }else if( handle.safeis("<") ) {
              handle.remove();
              handle.insert("extends");
            }else if( handle.safeis("::") ) {
              handle.remove();
              handle.insert("implements");
            }else if( handle.is("\n") ) {
              handle.insert("{");
              break;
            }

            handle.increment();
          }

        // Statics
        }else if( handle.safeisStart("self.") ) {
            handle.remove();
            handle.insert(this.name + ".");
            handle.increment();

        // Line break
        }else if( handle.is("\n") ) {
            var pos = handle.position;
            var insert = true;

            handle.prevTokenLine();
            if( handle.isOne(["=", ";", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "~", "\n", "}", "?", ":"])
            && this.only_whitespace(handle.content, handle.position + 1, pos) ) {
                insert = false;
            }

            handle.position = pos;
            handle.increment("\n");
            handle.nextToken();
            if( handle.isOne(["?", ":", "=", "*", ".", "/", "," , "|", "&", ")", "]", "^", "%", "~"])
            && this.only_whitespace(handle.content, pos + 1, handle.position - 1) ) {
                insert = false;
            }

            handle.prev("\n");
            if( insert ) {
                handle.insert(";");
                handle.increment();
            }

            handle.increment();

        // Otherwise, skip
        }else{
            handle.increment();
        }
    }

    handle.content = handle.content + "\n}";

    return handle.content;
}

/**
    Consume curlies (functions)
**/
private function consume_curlies(handle: StringHandle){
    var count = 0;

    while( handle.nextToken() ) {
        if( handle.is("(") ) {
            count++;
        }else if( handle.is(")") ) {
            count--;
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
        }else if( handle.is("\"") ) {
            this.process_string(handle);
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
    handle.nextToken();

    if( handle.position != position + 1 ) {
        handle.position = position;
        handle.remove();
        handle.insert("this.");
        handle.increment();
    }
}

/**
    Match whitespaces
**/
private function only_whitespace(content: String, from: Int, to: Int){
    var sub = content.substr(from, to - from);
    var regex = new  EReg("^\\s*$", "i");

    return regex.match(sub);
}

/**
    Process a string line
**/
private function process_string(handle: StringHandle){
    if( handle.at("\"\"\"") ) {
        handle.remove("\"\"\"");
        handle.insert("\"");
    }

    handle.increment();

    while( handle.nextToken() ) {
        if( handle.is("\"") &&
        (handle.content.charAt(handle.position -1) != "\\" ||
            (handle.content.charAt(handle.position -1) == "\\" &&
            handle.content.charAt(handle.position -2) == "\\"))
        ) {
            break;
        }

        handle.increment();
    }

    if( handle.at("\"\"\"") ) {
        handle.remove("\"\"\"");
        handle.insert("\"");
    }

    handle.increment();
}

/**
    Checks the visibility of a function or var
**/
private function check_visibility(handle: StringHandle, token: String){
    var pos = handle.position;
    var has_visibility = false;

    if( (this.opened == 0) ) {
        handle.prev("\n");
        while( (handle.nextToken() && handle.position <= pos) ) {
            if( (handle.is("public") || handle.is("private")) ) {
                has_visibility = true;
            }

            handle.increment();
        }

        handle.prev(token);
    }

    handle.remove();

    if( (!has_visibility && this.opened == 0) ) {
        handle.insert("public ");
        handle.increment();
    }
}

}