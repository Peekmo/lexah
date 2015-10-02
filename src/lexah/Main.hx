package lexah;

import mcli.Dispatch;
import lexah.cli.Cli;

class Main {
  static function main() {
  	var args = Sys.args();
  	Sys.setCwd(args.pop());
    new Dispatch(args).dispatch(new Cli());
  }
}
