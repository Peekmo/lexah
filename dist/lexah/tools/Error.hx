// vim: set ft=rb:
package lexah.tools;
using Lambda;
using StringTools;


class Error{

public static function create(errorType: String, error: String){
    throw '{"type": $errorType, "error": $error}';
}

}