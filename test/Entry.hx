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
        var table = hash.build(map, Mph.HashString, 3);

        trace( table );
        
        for (key in map.keys()) {
            trace( 'Looking up the key `$key` => `${map.get(key)}` in `table`, which is ' + hash.get(table, key, Mph.HashString) );
        }

        // Accessing a non-existent key, depending on platform, 
        // will result in an unexpected error or a false result.
        try {
            trace( hash.get(table, 'c', Mph.HashString) );

        } catch (e:Any) {
            trace( e );

        }

        var map = [[1, 2, 3] => 'a', [4] => 'b', [9, 8, 7, 6, 5, 99999999, 3, 2, 1] => 'c', [8, 7, 6, 5, 4, 3, 2, 1] => 'h',
        [7, 6, 5, 4, 3, 2, 1] => 'd', [6, 5, 4, 3, 2, 1] => 'e', [5, 4, 3, 2, 1] => 'f', [4, 3, 2, 1] => 'g', /*[3, 2, 1] => 'h',*/ [2, 1] => 'c', [1] => 'i',
        ];
        var hash = new Mph();
        var table = hash.build(map, Mph.HashIterable);

        trace( table );

        for (key in map.keys()) {
            trace( 'Looking up the key `$key` => `${map.get(key)}` in `table`, which is ' + hash.get(table, key, Mph.HashIterable) );
        }
    }

}