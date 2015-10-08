// vim: set ft=rb:
package lexah.transpiler;

import lexah.tools.StringHandle;

using Lambda;
using StringTools;

class TranspilerGroup{

public var transpilers: Array<TranspilerInterface>;

public function new(){
    this.transpilers = new  Array<TranspilerInterface>();
}

public function push(transpiler: TranspilerInterface): TranspilerGroup{
    this.transpilers.push(transpiler);

    return this;
}

}