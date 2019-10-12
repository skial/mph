package hash;

import haxe.Int32;
import haxe.ds.Vector;
import haxe.ds.ArraySort;

using haxe.Int32;
using StringTools;

// Based on
// @see http://stevehanov.ca/blog/?id=119

typedef Table<Key, Value> = {
    keys:Vector<Null<Key>>,
    values:Vector<Value>,
}

/**
    Bitwise ops, afaik, _generally_ only work on 32bit ints/ranges? But
    this doesnt hold for each target, 🤷‍♀️, so the math isnt identical 
    cross-platform.
    Which is an issue when you are embedding the table via macros and
    which is why its typed to `Int32`.
**/

//
class Mph {

    @:nullSafety(Strict) public static function HashString(d:Int32, value:String):Int32 {
        if (d == 0) {
            d =  16777619;
        }

        for (i in 0...value.length) {
            d = UnsafeHash( d, value.fastCodeAt(i) );
        }

        return d;
    }

    @:nullSafety(Strict) public static function HashIterator(d:Int32, values:Iterator<Int32>):Int32 {
        if (d == 0) {
            d =  16777619;
        }
        
        for (value in values) {
            d = UnsafeHash( d, value );
        }

        return d;
    }

    @:nullSafety(Strict) public static inline function HashIterable(d:Int32, values:Iterable<Int32>):Int32 {
        return HashIterator(d, values.iterator());
    }

    @:nullSafety(Strict) public static function Hash(d:Int32, value:Int32):Int32 {
        if (d == 0) {
            d =  16777619;
        }

        return UnsafeHash( d, value );
    }

    @:nullSafety(Strict) public static inline function UnsafeHash(d:Int32, value:Int32):Int32 {
        return (d * 16777619) ^ value & 2147483647;
    }

    #if (eval || macro)
    public static function asExpr<V>(table:hash.Mph.Table<Int, V>):haxe.macro.Expr.ExprOf<hash.Mph.Table<Int, V>> {
        return macro { 
            keys:haxe.ds.Vector.fromArrayCopy([ $a{table.keys.toArray().map( k -> macro $v{k} )} ]),
            values:haxe.ds.Vector.fromArrayCopy([ $a{table.values.toArray().map( k -> macro $v{k} )} ])
        };
    }
    #end

    public function new() {}

    /**
        `Mph::build` and `Mph::makes` `if (d%size == 0)` are from
        @see https://github.com/ChrisTrenkamp/mph/

    **/

    /** 
        Retries to build table up to `maxAttempts` times.
        If it fails, it will throw an exception.
    **/
    #if static @:generic #end
    public function build<K, V>(object:Map<K, V>, hasher:Int32->K->Int32, size:Int32 = 0, maxAttempts:Int = 100):Table<Int, V> {
        var table = null;
        var loadFactor = 1.0;
        if (size <= 0) for (key in object.keys()) size++;

        var attempt = 0;

        while (attempt < maxAttempts && table == null) {
            table = make( object, hasher, size );
            loadFactor *= 0.9;
            size = Std.int(size / loadFactor);

        }

        if (table == null) throw 'Unable to build table after $maxAttempts attempts.';

        return table;
    }

    #if static @:generic #end
    public function make<K, V>(object:Map<K, V>, hasher:Int32->K->Int32, size:Int = 0):Table<Int, V> {
        if (size <= 0) for (key in object.keys()) size++;
        var buckets = [];
        var keys:Vector<Null<Int>> = new Vector(size);
        var values:Vector<V> = new Vector(size);

        for (key in object.keys()) {
            var hash = hasher(0, key);
            var bucketKey = (hash % size);
            
            if (buckets[bucketKey] == null) {
                buckets[bucketKey] = [];
            }

            buckets[bucketKey].push( key );
            
        }

        ArraySort.sort( buckets, function (a, b) {
            if (a == null) return 1;
            if (b == null) return -1;
            return b.length - a.length;
        } );

        var i = 0;
        var bucket = [];
        while (i < size) {
            if (buckets[i] == null || buckets[i].length <= 1) break;
            bucket = buckets[i];
            
            var d = 1;
            var item = 0;
            var slot = 0;
            var slots = [];
            var used:Array<Bool> = [];

            while (item < bucket.length) {
                slot = (hasher(d, bucket[item]) % size);
                
                if (values[slot] != null || (#if !static used[slot] != null && #end used[slot] == true)) {
                    d++;
                    item = 0;
                    slots = [];
                    used = [];

                    if (d%size == 0) {
                        return null;
                    }

                } else {
                    used[slot] = true;
                    slots.push(slot);
                    item++;

                }

            }

            keys[(hasher(0, bucket[0]) % size)] = d;

            for (i in 0...bucket.length) {
                values[slots[i]] = object.get(bucket[i]); 
            }

            i++;

        }

        var freelist = [];
        for (x in 0...size) {
            if (values[x] == null) {
                freelist.push(x);

            }

        }

        while (i < size) {
            if (buckets[i] == null || buckets[i].length == 0) break;
            var bucket = buckets[i];
            var slot = freelist.pop();

            keys[(hasher(0, bucket[0]) % size)] = 0-slot-1;
            values[slot] = object.get(bucket[0]);

            i++;

        }

        return {keys: keys, values: values};
    }

    #if static @:generic #end
    public function get<K, V>(table:Table<Int, V>, key:K, hasher:Int32->K->Int32):V {
        var d = table.keys[(hasher(0, key) % table.keys.length)];
        if (d < 0) return table.values[0-d-1];
        return table.values[(hasher(d, key) % table.values.length)];
    }

}