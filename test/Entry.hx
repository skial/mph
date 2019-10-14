package ;

import tink.unit.*;
import tink.testrunner.Runner;

#if js
@:jsRequire('../index.js')
extern class MPH {
    public static function create(obj:{}):Array<Any>;
    public static function lookup(keys:Array<Int>, values:Array<String>, key:String):String;
}
#end

class Entry {

    public static function main() {
        Runner.run(TestBatch.make([
            new hash.MphSpec(),
        ]))
        .handle(Runner.exit);
    }

}