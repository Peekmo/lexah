// vim: set ft=rb:
package lexah.transpiler;

import lexah.tools.StringHandle;

using Lambda;
using StringTools;

interface TranspilerInterface{

public function tokens(): Array<String>;
public function transpile(handle: StringHandle): String;

}