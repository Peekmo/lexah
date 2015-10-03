package lexah.transpiler;using Lambda;using StringTools;import lexah.tools.StringHandle;

interface TranspilerInterface{

public function tokens(): Array<String>;
public function transpile(handle: StringHandle): String;

}