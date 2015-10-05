// vim: set ft=rb:
package lexah.tools;

import sys.FileSystem;
import sys.io.File;

using Lambda;
using StringTools;

class FolderReader{

/**
    Returns an array of all files which are in the given folder and its subfolders

    @param root_folder : String Root folder for the search

    @return Files found
**/
public static function get_files(root_folder: String): Array<String>{
    var files = new  Array<String>();

    if( FileSystem.exists(root_folder) ){
        var folders = FileSystem.readDirectory(root_folder);

        for( file in folders.iterator() ){
            var path = root_folder + "/" + file;

            if( FileSystem.isDirectory(path) ){
                var data = FolderReader.get_files(path);

                for( i in data ){
                    files.push(i);
                }
            }else{
                files.push(path);
            }
        }
    }

    return files;
};

/**
    Creates a file to the given path, with the given content
    (Creates all directories if they not exists)

    @param path     String Path to the file
    @param ?content String File's content
**/
public static function create_file(path: String, ?content: String): Void{
    var parts = path.split("/");
    var fileName = parts.pop();

    FolderReader.create_directory(parts.join("/"));

    if( content == null ){
        content = "";
    }

    File.saveContent(path, content);
};

/**
    Creates the given directory (and all path's directories if needed)

    @param path String Path to the given directory
**/
public static function create_directory(path: String): Void{
    var parts = path.split("/");
    var done : String = null;

    for( part in parts.iterator() ){
        done = done == null ? part : done + "/" + part;

        if( !FileSystem.exists(done) ){
            FileSystem.createDirectory(done);
        }
    }
};

/**
    Copy all files from source to destination

    @param  source      String Source's path
    @param  destination String Destination's path
**/
public static function copy_file_system(source: String, destination: String): Void{
    try {
        if( source.endsWith("/") ){
            source = source.substr(0, -1);
        }

        // File
        if( !FileSystem.isDirectory(source) ){
            FolderReader.create_file(destination, File.getContent(source));

        // Directory
        }else{
            var files = FileSystem.readDirectory(source);

            for( file in files.iterator() ){
                if( FileSystem.isDirectory('$source/$file') ){
                    FolderReader.create_directory(destination);
                }

                FolderReader.copy_file_system('$source/$file', '$destination/$file');
            }
        }
    } catch( msg: String){
        throw 'Unable to copy $source to $destination : $msg';
    }
};

}