// vim: set ft=rb:
package lexah.tools;

using Lambda;
using StringTools;

class StringHandle{

public var content: String;
public var position: Int;
public var current: String;
public var tokens: Array<String>;

public function new(content: String, ?tokens: Array<String>, position: Int = 0){
    this.content = content;

    if( tokens == null ){
        this.tokens = ["\n"];
    }else{
        this.tokens = tokens;
    }

    this.position = position;
};

/**
    Reset position and text
**/
public function reset() : Void{
    this.position = 0;
    this.current = null;
};

/**
    Check if we are in the beginning of @current
**/
public function atStart() : Bool{
    return this.position <= 0;
};

/**
    Check if we are in the end of @current
**/
public function atEnd() : Bool{
    return this.position >= this.content.length;
};

/**
    Check if we are in near the beginning of @current
**/
public function nearStart(tolerance: Int) : Bool{
    return (this.position - tolerance) <= 0;
};

/**
    Check if we are in near the end of @current
**/
public function nearEnd(tolerance: Int) : Bool{
    return (this.position + tolerance) > this.content.length;
};

/**
    Splits the text in 2 parts
**/
public function divided(?offset: Int = 0){
    return {
        left: (this.position + offset) > 0;
            ? this.content.substr(0, this.position + offset);
            : "",
        right: (this.position + offset) < this.content.length;
            ? this.content.substring(this.position + offset);
            : "";
    };
};

}