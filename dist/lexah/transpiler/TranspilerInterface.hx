package lexah.transpiler;using Lambda;using StringTools;// vim: set ft=rb:
import lexah.tools.StringHandle;

interface TranspilerInterface{

public function tokens(): Array<String>;
public function transpile(handle: StringHandle): String;

}