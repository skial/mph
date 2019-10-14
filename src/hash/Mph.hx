package hash;

import haxe.Int32;
import haxe.ds.Vector;
import haxe.ds.ArraySort;

using haxe.Int32;
using StringTools;

/**
    Based on
    @see http://stevehanov.ca/blog/?id=119
**/

typedef Table<Key, Value> = {
    keys:Vector<Null<Key>>,
    values:Vector<Value>,
}

typedef Access<Key, Value> = {
    function get(key:Key):Null<Value>;
    function keys():Iterator<Key>;
}

@:forward
@:forwardStatics
abstract Container<Key, Value>(Access<Key, Value>) from Access<Key, Value>{

    public inline function new(v) this = v;

    @:from public static inline function fromMap<K, V>(v:haxe.Constraints.IMap<K, V>):Container<K, V> {
        return new Container(v);
    }

    #if tink_core
    @:from public static inline function fromTinkPair<K, V>(v:tink.core.Pair<Array<K>, Array<V>>):Container<K, V> {
        return fromPair(cast v);
    }
    #end

    @:from public static inline function fromPair<K, V>(v:{a:Array<K>, b:Array<V>}):Container<K, V> {
        if (v.a.length != v.b.length) throw 'Array lengths must match.';
        return new Container(new ArrayWrap(v.a, v.b));
    }

}

private class ArrayWrap<Key, Value> {

    public var _keys:Array<Key> = [];
    public var values:Array<Value> = [];

    public function new(a:Array<Key>, b:Array<Value>) {
        _keys = a;
        values = b;
    }

    public function keys():Iterator<Key> {
        return _keys.iterator();
    }

    public function get(key:Key):Null<Value> {
        var keyIndex = _keys.indexOf(key);
        if (keyIndex == -1) return null;
        return values[keyIndex];
    }

}

/**
    Bitwise ops, afaik, _generally_ only work on 32bit ints/ranges? But
    this doesnt hold for each target, 🤷‍♀️, so the math isnt identical 
    cross-platform using `Int`.
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

    @:nullSafety(Strict) public static function HashArray(d:Int32, values:Array<Int32>):Int32 {
        if (d == 0) {
            d =  16777619;
        }
        
        for (i in 0...values.length) {
            d = UnsafeHash( d, values[i] );
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
    public static function asExpr<V>(table:hash.Mph.Table<Int, V>, ?valueExpr:V->haxe.macro.Expr):haxe.macro.Expr.ExprOf<hash.Mph.Table<Int, V>> {
        if (valueExpr == null) valueExpr = v -> macro $v{v};
        return macro { 
            keys:haxe.ds.Vector.fromArrayCopy([ $a{table.keys.toArray().map( k -> macro $v{k} )} ]),
            values:haxe.ds.Vector.fromArrayCopy([ $a{table.values.toArray().map( k -> valueExpr(k) )} ])
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
    public function build<K, V>(object:Container<K, V>, hasher:Int32->K->Int32, size:Int32 = 0, maxAttempts:Int = 100):Table<Int, V> {
        var table = null;
        var loadFactor = 1.0;
        if (size <= 0) for (key in object.keys()) size++;

        var attempt = 0;

        while (attempt < maxAttempts && table == null) {
            table = make( object, hasher, size );
            loadFactor *= 0.9;
            size = Std.int(size / loadFactor);
            
            attempt++;
        }

        if (table == null) throw 'Unable to build table after $maxAttempts attempts.';

        return table;
    }

    #if static @:generic #end
    public function make<K, V>(map:Container<K, V>, hasher:Int32->K->Int32, size:Int = 0):Table<Int, V> {
        if (size <= 0) for (key in map.keys()) size++;
        var buckets = [];
        var keys:Vector<Null<Int>> = new Vector(size);
        var values:Vector<V> = new Vector(size);

        for (key in map.keys()) {
            var hash = hasher(0, key);
            var bucketKey = (hash % size);
            
            if (buckets[bucketKey] == null) {
                buckets[bucketKey] = [];
            }

            buckets[bucketKey].push( key );

            if (buckets[bucketKey].length > size/2) {
                return null;
            }
            
        }

        ArraySort.sort( buckets, function (a, b) {
            if (a == null) return 1;
            if (b == null) return -1;
            return b.length - a.length;
        } );

        var i = 0;
        var bucket = [];

        while (i < size) {
            bucket = buckets[i];
            if (bucket == null || buckets.length == 0) break;
            
            var d = 1;
            var item = 0;
            var slot = 0;
            var slots:Array<Int> = [];

            while (item < bucket.length) {
                slot = hasher(d, bucket[item]) % size;
                
                if (values[slot] != null || slots.indexOf(slot) > -1) {
                    d++;
                    item = 0;
                    slots = [];

                    if (d % size == 0) {
                        return null;
                    }

                } else {
                    slots.push(slot);
                    item++;

                }

            }

            keys[(hasher(0, bucket[0]) % size)] = d;

            for (i in 0...bucket.length) {
                values[slots[i]] = map.get(bucket[i]); 
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
            values[slot] = map.get(bucket[0]);

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