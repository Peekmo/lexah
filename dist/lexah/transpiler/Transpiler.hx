package lexah.transpiler;

import lexah.tools.StringHandle;
import sys.io.File;

class Transpiler {
  public function new() {}

  var path : String = "";
  var name : String = "";
  var currentType : String = "";
  var opened = 0;

  public function transpile(directory : String, file : String) : String {
    var currentPackage = StringTools.replace(file, directory, "");
    currentPackage = StringTools.replace(currentPackage, "\\", "/");
    var currentModule = StringTools.replace(currentPackage.substr(currentPackage.lastIndexOf("/") + 1), ".lxa", "");
    currentPackage = StringTools.replace(currentPackage, currentPackage.substr(currentPackage.lastIndexOf("/")), "");
    currentPackage = StringTools.replace(currentPackage, "/", ".");

    if (currentPackage.charAt(0) == ".") currentPackage = currentPackage.substr(1);

    var content = File.getContent(file);

    this.name = currentModule;
    this.path = currentPackage;

    return this.run(new StringHandle(content, this.tokens()));
  }

  public function tokens() : Array<String> {
    return [
      // Line break
      "\n",

      // Inheritance & interfaces
      "<", "::",

      // Comments
      "##*", "*##", "##",

      // Lexah keywords
      "-", "require", "def", ".new", "self.", "self", "end", "do", "puts", "raise", "begin", "rescue", "const", "module", "var",

      // Standard keywords
      "![", "]", "@{", "}", "\\", "\"", "\\\"", "(", ")", "/", "=", "#", ",", "@:", "@", ":", "*", "{", "}", ".", ";", "?", "[", "]",

      // Expressions
      "elsif", "if", "else", "while", "for", "then", "and", "or",

      // Types
      "class", "enum", "abstract", "interface",

      // Modifiers
      "private", "public",
    ];
  }

  private function run(handle : StringHandle) {
    var isFixed = false;
    var fullyFixed = false;

    while (handle.nextToken()) {
      // Process comments and ignore everything in
      // them until end of line or until next match if multiline
      if (handle.is("##*")) {
        handle.remove();
        handle.insert("/**");
        while(handle.nextToken()) {
          if (handle.is("*##")) {
            handle.remove();
            handle.insert("**/");
            handle.increment();
            break;
          }

          handle.increment();
        }
      } else if (handle.is("##")) {
        handle.remove();
        handle.insert("//");
        handle.increment();
        handle.next("\n");
        handle.increment();
      }
      // Invoke pure haxe code
      else if (handle.is("@{")) {
        handle.remove();
        handle.next("}");
        handle.remove();
        handle.increment();
      }
      // Const
      else if (handle.is("const")) {
        handle.remove();
        handle.insert("public static inline var");
        handle.increment();
      }
      // Informations about a functions
      else if (handle.is("![")) {
        handle.remove();
        var startPosition = handle.position;
        handle.increment();

        handle.next("]");
        var finalPosition = handle.position;
        handle.position = startPosition;
        var comas = 0;

        while (true) {
          if (!handle.next(",") && handle.position < finalPosition) {
            handle.next("]");
            handle.remove();
            handle.nextToken();
            break;
          }

          if (handle.position > finalPosition) {
            handle.position = finalPosition - comas;
            // If some "," removed
            if (comas != 0) {
              handle.prev("]");
            }

            handle.remove();
            handle.nextToken();
            break;
          }

          comas++;
          handle.remove();
        }

        if (handle.is("\n")) {
          handle.remove();
          handle.insert(" ");
          handle.increment();
        }
      }
      // Skip compiler defines
      else if (handle.is("#")) {
        handle.next("\n");
      }
      // this. and compiler infos
      else if (handle.is("@")) {
        checkThis(handle);
      }
      // Step over things in strings (" ") and process multiline strings
      else if (handle.is("\"")) {
        if (handle.at("\"\"\"")) {
          handle.remove("\"\"\"");
          handle.insert("\"");
        }

        handle.increment();

        while (handle.nextToken()) {
          if (handle.is("#")) {
            handle.remove();
            handle.insert("$");
            handle.increment();
          } else if (handle.is("\"")) {
            break;
          } else {
            handle.increment();
          }
        }

        if (handle.at("\"\"\"")) {
          handle.remove("\"\"\"");
          handle.insert("\"");
        }

        handle.increment();
      }
      else if (handle.is(".new")) {
        handle.remove();
        handle.prevTokenLine();

        while(true) {
          if (!handle.isOne(["=", ":", "\n", ".", "(", "[", ";", ","])) {
            handle.prevTokenLine();
          } else {
            break;
          }
        }

        handle.increment();
        handle.insert(" new ");
        handle.increment();
      }
      else if (handle.safeis("puts")) {
        handle.remove();
        handle.insert("trace");
        handle.increment();
      }
      else if (handle.safeis("begin")) {
        handle.remove();
        handle.insert("try {");
        handle.increment();
      }
      else if (handle.safeis("raise")) {
        handle.remove();
        handle.insert("throw");
        handle.increment();
      }
      else if (handle.safeis("rescue")) {
        handle.remove();
        handle.insert("} catch");
        handle.increment();
        handle.insert("(");
        handle.next("\n");
        handle.insert("){");
        handle.increment();
      }
      // Change end to classic bracket end
      else if (handle.safeis("end")) {
        handle.remove();
        handle.insert("}");
        this.opened--;
        handle.increment();
      }
      // Module = package
      else if (handle.safeis("module")) {
        handle.remove();
        handle.insert("package");
        handle.increment();
        handle.next("\n");
      }
      // Change require to classic imports
      else if (handle.safeis("require")) {
        handle.remove();
        handle.insert("import");
        handle.increment();

        var firstQuote = true;

        while (handle.nextToken()) {
          if (handle.is("\"")) {
            handle.remove();

            if (!firstQuote) {
              handle.insert(";");
              handle.increment();
              handle.increment();
              break;
            }

            firstQuote = false;
          } else if (handle.is("/")) {
            handle.remove();
            handle.insert(".");
          }

          handle.increment();
        }
      }
      // Defines to variables and functions
      else if (handle.safeis("def")) {
        this.checkVisibility(handle, "def");

        handle.insert("function");
        handle.next("\n");

        if (this.currentType == "class") {
          handle.insert("{");
        } else if (this.currentType == "interface") {
          handle.insert(";");
        }

        handle.increment();
        this.opened++;
      }
      else if (handle.safeis("var")) {
        this.checkVisibility(handle, "var");

        handle.insert("var");
        handle.increment();
      }
      // Defines to variables and functions
      else if (handle.safeis("do")) {
        handle.remove();
        handle.insert("function");
        handle.increment();
        handle.insert("{");
        handle.increment();
        this.opened++;
      }
      // Insert begin bracket after if and while
      else if (handle.safeis("if")) {
        handle.increment();
        consumeCondition(handle, "then");
      }
      // Change elseif to else if and insert begin and end brackets around it
      else if (handle.safeis("elsif")) {
        handle.remove();
        handle.insert("}else if");
        handle.increment();
        this.opened--;
        consumeCondition(handle, "then");
      }
      else if (handle.safeis("while") || handle.safeis("for")) {
        handle.increment();
        consumeCondition(handle, "do");
      }
      else if (handle.safeis("next")) {
        handle.remove();
        handle.insert("continue");
        handle.increment();
      }
      // Inser begin and end brackets around else but do not try to
      // process curlys because there will not be any
      else if (handle.safeis("else")) {
        handle.insert("}");
        handle.increment();
        handle.increment("else");
        handle.insert("{");
        handle.increment();
      }
      // [abstract] class/interface/enum
      else if (handle.safeis("class") || handle.safeis("interface") || handle.safeis("enum")) {
        this.currentType = handle.current;
        handle.remove();
        handle.insert("using Lambda;\nusing StringTools;\n\n").increment();
        handle.insert(this.currentType);

        handle.increment();

        while(handle.nextToken()) {
          if (handle.is("self")) {
            handle.remove();
            handle.insert(name);
          } else if (handle.safeis("<")) {
            handle.remove();
            handle.insert("extends");
          } else if (handle.safeis("::")) {
            handle.remove();
            handle.insert("implements");
          } else if (handle.is("\n")) {
            handle.insert("{");
            break;
          }

          handle.increment();
        }
      }
      else if (handle.safeisStart("self.")) {
        handle.remove();
        handle.insert(name + ".");
        handle.increment();
      }
      else if (handle.is("\n")) {
        var pos = handle.position;
        var insert = true;

        handle.prevTokenLine();
        if (handle.isOne(["=", ";", "+", "-", "*", ".", "/", "," , "|", "&", "{", "(", "[", "^", "%", "~", "\n", "}", "?", ":"]) && onlyWhitespace(handle.content, handle.position + 1, pos)) {
            insert = false;
        }

        handle.position = pos;
        handle.increment("\n");
        handle.nextToken();
        if (handle.isOne(["?", ":", "=", "+", "-", "*", ".", "/", "," , "|", "&", ")", "]", "^", "%", "~"]) && onlyWhitespace(handle.content, pos + 1, handle.position - 1)) {
            insert = false;
        }

        handle.prev("\n");
        if (insert) {
            handle.insert(";");
            handle.increment();
        }

        handle.increment();
      }
      else {
        handle.increment(); // Skip this token
      }
    }

    handle.content = handle.content + "\n}";

    return handle.content;
  }

  private function consumeCurlys(handle : StringHandle) {
    var count = 0;

    while(handle.nextToken()) {
      if (handle.is("(")) {
        count++;
      } else if (handle.is(")")) {
        count--;
      }

      handle.increment();
      if (count == 0) break;
    }
  }

  private function consumeCondition(handle: StringHandle, token: String) {
    handle.insert("(");

    while (handle.nextToken()) {
      if (handle.safeis(token)) {
        handle.remove();
        break;
      } else if (handle.safeis("and")) {
        handle.remove();
        handle.insert("&&");
      } else if (handle.safeis("or")) {
        handle.remove();
        handle.insert("||");
      } else if (handle.is("@")) {
        checkThis(handle);
      }

      handle.increment();
    }

    handle.insert(") {");
    handle.increment(") {");
    this.opened++;
  }

  private function checkThis(handle: StringHandle) {
      var position = handle.position;
      handle.nextToken();

      if (handle.position != position + 1) {
        handle.position = position;
        handle.remove();
        handle.insert("this.");
        handle.increment();
      }
  }

  private function checkVisibility(handle: StringHandle, token: String) {
      var pos = handle.position;
      var hasVisibility = false;

      if (this.opened == 0) {
          handle.prev("\n");
          while (handle.nextToken() && handle.position <= pos) {
              if (handle.is("public") || handle.is("private")) {
                  hasVisibility = true;
              }

              handle.increment();
          }

          handle.prev(token);
      }

      handle.remove();

      if (!hasVisibility && this.opened == 0) {
          handle.insert("public ");
          handle.increment();
      }
  }

  private function onlyWhitespace(content : String, from : Int, to : Int) {
    var sub = content.substr(from, to - from);
    var regex = ~/^\s*$/;
    return regex.match(sub);
  }
}
