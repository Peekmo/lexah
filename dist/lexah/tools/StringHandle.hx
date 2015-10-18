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

    if( tokens == null ) {
        this.tokens = ["\n"];
    }else{
        this.tokens = tokens;
    }

    this.position = position;
}

/**
    Reset position and text
**/
public function reset() : Void{
    this.position = 0;
    this.current = null;
}

/**
    Check if we are in the beginning of @current
**/
public function atStart() : Bool{
    return this.position <= 0;
}

/**
    Check if we are in the end of @current
**/
public function atEnd() : Bool{
    return this.position >= this.content.length;
}

/**
    Check if we are in near the beginning of @current
**/
public function nearStart(tolerance: Int) : Bool{
    return (this.position - tolerance) <= 0;
}

/**
    Check if we are in near the end of @current
**/
public function nearEnd(tolerance: Int) : Bool{
    return (this.position + tolerance) > this.content.length;
}

/**
    Go to the closest token
**/
public function closest(content: String): Bool{
    var divided = this.divide();
    var regex = new EReg("[^\\w][ \t]*" + content, "");
    var sub = this.content.substr(this.position);

    var count = 1;
    while( true ) {
        if( sub.charAt(count) == " "
        || sub.charAt(count) == "\t"
        || sub.charAt(count) == "\n" ) {
            count++;
        }else{
            break;
        }
    }

    return regex.match(sub.substr(0, count));
}

/**
    Checks if the current is the content
**/
public function is(content: String): Bool{
    return this.current == content;
}

/**
    Checks if the current is in the given array
**/
public function isOne(content: Array<String>): Bool{
    var contains = false;

    for( cnt in content ) {
        contains = contains || this.current == cnt;
    }

    return contains;
}

/**
    Token started by whitespace
**/
public function safeisStart(content: String): Bool{
    var regex = new EReg("[^\\w]" + content, "");

    if( this.nearStart(1) ) {
        return this.is(content);
    }

    if( this.nearEnd(content.length + 1) ) {
        return this.is(content);
    }

    var sub = this.content.substr(
        this.nearStart(1) ? this.position : this.position - 1,
        this.nearEnd(content.length + 1) ? content.length : content.length + 1
    );

    return regex.match(sub);
}

/**
    Token ended by whitespace
**/
public function safeisEnd(content: String): Bool{
    var regex = new EReg(content + "[^\\w]", "");

    if( this.nearEnd(content.length + 2) ) {
        return this.is(content);
    }

    var sub = this.content.substr(
        0,
        this.nearEnd(content.length+2) ? content.length : content.length+2
    );

    return regex.match(sub);
}

/**
    Token started and ended by withespace
**/
public function safeis(content: String): Bool{
    var regex = new EReg("[^\\w]" + content + "[^\\w]", "");

    if( this.nearStart(1) ) {
        return this.safeisEnd(content);
    }

    if( this.nearEnd(content.length + 2) ) {
        return this.safeisStart(content);
    }

    var sub = this.content.substr(this.position-1, content.length + 2);

    return regex.match(sub);
}

/**
    Checks for the exact word
**/
public function is_word(content: String): Bool{
    var regex = new EReg("[\\s]" + content + "[\\s]", "");
    var offsetStart = 1;
    var offsetEnd = 2;

    if( this.nearStart(1) ) {
        offsetStart = 0;
    }

    if( this.nearEnd(content.length + 2) ) {
        offsetEnd = 1;
    }

    var sub = this.content.substr(this.position-offsetStart, content.length + offsetEnd);

    return regex.match(sub);
}

/**
    Checks if the content to the right is...
**/
public function at(content: String): Bool{
    var divided = this.divide();

    if( divided.right.substr(0, content.length) == content ) {
        return true;
    }

    return false;
}

/**
    Get the previous given token
    Returns the previous same token as current one if content is not provided
**/
public function prev(?content: String): Bool{
    if( content == null ) {
        if( this.current != null ) {
            return this.prev(this.current);
        }

        return false;
    }

    var new_pos = this.content.substr(0, this.position).lastIndexOf(content);

    if( new_pos == -1 ) {
        return false;
    }

    this.position = new_pos;
    this.current  = content;
    return true;
}

/**
    Get the next given token
    Returns the next same token as current one if content is not provided
**/
public function next(?content: String): Bool{
    if( content == null ) {
        if( this.current != null ) {
            return this.next(this.current);
        }

        return false;
    }

    var new_pos = this.content.indexOf(content, this.position);
    if( new_pos == -1 ) {
        return false;
    }

    this.position = new_pos;
    this.current  = content;
    return true;
}

/**
    Gets the previous token
**/
public function prevToken(): Bool{
    var new_pos = this.position + 1;
    var current_token = "";

    for( token in tokens ) {
        var pos = this.content.substr(0, this.position).lastIndexOf(token);

        if( pos != -1 && (pos > new_pos || new_pos == this.position + 1) ) {
            new_pos = pos;
            current_token = token;
        }
    }

    if( new_pos == -1 ) {
        return false;
    }

    this.position = new_pos;
    this.current  = current_token;
    return true;
}

/**
    Gets the previous token on the same line
**/
public function prevTokenLine(): Bool{
    var new_pos = this.position + 1;
    var current_token = "";

    for( token in tokens ) {
        var pos = this.content.substr(0, this.position).lastIndexOf(token);

        if( pos != -1 && (pos > new_pos || new_pos == this.position + 1) ) {
            new_pos = pos;
            current_token = token;
        }
    }

    var pos = this.content.substr(0, this.position).lastIndexOf("\n");
    if( pos != -1 && (pos > new_pos || new_pos == this.position+1) ) {
        new_pos = pos;
        current_token = "\n";
    }

    if( new_pos == -1 ) {
        return false;
    }

    this.position = new_pos;
    this.current  = current_token;
    return true;
}

/**
    Gets the next token on the same line
**/
public function nextTokenLine(): Bool{
    var new_pos = -1;
    var current_token = "";

    for( token in tokens ) {
        var pos = this.content.indexOf(token, this.position);

        if( pos != -1 && (pos < new_pos || new_pos == -1) ) {
            new_pos = pos;
            current_token = token;
        }
    }

    var pos = this.content.indexOf("\n", this.position);
    if( pos != -1 && (pos < new_pos || new_pos == -1) ) {
        new_pos = pos;
        current_token = "\n";
    }

    if( new_pos == -1 ) {
        return false;
    }

    this.position = new_pos;
    this.current  = current_token;
    return true;
}

/**
    Next token (not safe)
**/
public function nextToken(): Bool{
    var new_pos = -1;
    var current_token = "";

    for( token in tokens ) {
        var pos = this.content.indexOf(token, this.position);

        if( pos != -1 && (pos < new_pos || new_pos == -1) ) {
            new_pos = pos;
            current_token = token;
        }
    }

    if( new_pos == -1 ) {
        return false;
    }

    this.position = new_pos;
    this.current  = current_token;
    return true;
}

/**
    Increment position from the current token
**/
public function increment(?content: String): StringHandle{
    if( content == null ) {
        if( this.current != null ) {
            this.increment(this.current);
        }

        return this;
    }

    var new_pos = this.position + content.length;

    if( new_pos > this.content.length ) {
        return this;
    }

    this.position = new_pos;
    this.current = content;
    return this;
}

/**
    Decrement position from the current token
**/
public function decrement(?content: String): StringHandle{
    if( content == null ) {
        if( this.current != null ) {
            this.decrement(this.current);
        }

        return this;
    }

    var new_pos = this.position - content.length;

    if( new_pos < 0 ) {
        return this;
    }

    this.position = new_pos;
    this.current = content;
    return this;
}

/**
    Insert content to the given position
**/
public function insert(?content: String): StringHandle{
    if( content == null ) {
        if( this.current != null ) {
            this.insert(this.current);
        }

        return this;
    }

    var divided = this.divide();

    this.content = divided.left + content + divided.right;
    this.current = content;
    return this;
}

/**
    Remove content to the given position
**/
public function remove(?content: String): StringHandle{
    if( content == null ) {
        if( this.current != null ) {
            this.remove(this.current);
        }

        return this;
    }

    var length = content.length;
    var divided = this.divide();

    if( divided.right.length < length ) {
        return this;
    }

    this.content = divided.left + divided.right.substr(length);
    this.current = content;
    return this;
}

/**
    Splits the text in 2 parts
**/
public function divide(?offset: Int = 0){
    return {
        left: (this.position + offset) > 0
            ? this.content.substr(0, this.position + offset)
            : "",
        right: (this.position + offset) < this.content.length
            ? this.content.substring(this.position + offset)
            : "",
    }
}

}