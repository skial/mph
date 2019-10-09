package ;

import hash.*;

#if js
@:jsRequire('../index.js')
extern class MPH {
    public static function create(obj:{}):Array<Any>;
    public static function lookup(keys:Array<Int>, values:Array<String>, key:String):String;
}
#end

class Entry {

    public static function main() {
        var map = ['a'=>'A', 'b'=>'B', 'cCCCC'=>'C'];
        #if js
        var table = MPH.create({'a':'A', 'b':'B', 'cCCCC':'C'});
        trace( table );
        for (key in map.keys()) {
            trace( 'Looking up the key `$key` => `${map.get(key)}` in `table`, which is ' + MPH.lookup(table[0], table[1], key) );
        }
        #end
        var hash = new Mph();
        var table = hash.make(map);
        trace( table );
        
        for (key in map.keys()) {
            trace( 'Looking up the key `$key` => `${map.get(key)}` in `table`, which is ' + hash.get(table, key) );
        }

        // Accessing a non-existent key, depending on platform, 
        // will result in an unexpected error or a false result.
        try {
            trace( hash.get(table, 'c') );

        } catch (e:Any) {
            trace( e );

        }
    }

}