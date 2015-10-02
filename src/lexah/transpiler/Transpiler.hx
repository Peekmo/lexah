package lexah.transpiler;

import lexah.tools.StringHandle;

interface Transpiler {
  public function tokens() : Array<String>;
  public function transpile(handle : StringHandle) : String;
}
