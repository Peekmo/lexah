package lexah.tools;using Lambda;using StringTools;// vim: set ft=rb:
class Error{

public static function create(errorType: String, error: String){
    throw '{"type": $errorType, "error": $error}';
};

}