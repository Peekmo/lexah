package lexah.transpiler;

import lexah.tools.StringHandle;

class TranspilerGroup {
  var transpilers : Array<TranspilerInterface>;

  public function new() {
    transpilers = new Array<TranspilerInterface>();
  }

  public function push(transpiler : TranspilerInterface) : TranspilerGroup {
    transpilers.push(transpiler);
    return this;
  }
}
