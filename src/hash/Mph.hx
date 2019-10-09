package hash;

import haxe.Int32;
import haxe.ds.Vector;
import haxe.ds.ArraySort;

using haxe.Int32;
using StringTools;

// @see http://stevehanov.ca/blog/?id=119

typedef Table<Key, Value> = {
    keys:Vector<Null<Key>>,
    values:Vector<Value>,
}

class Mph {

    public function new() {}

    public function hash(d:Int32, value:String):Int32 {
        if (d == 0) {
            d =  16777619;
        }

        for (i in 0...value.length) {
            d = ((d * 16777619) ^ value.fastCodeAt(i)) & 2147483647;
        }

        return d;
    }

    #if static @:generic #end
    public function make<V>(object:Map<String, V>):Table<Int, V> {
        var size = 0;
        for (key in object.keys()) size++;
        
        var buckets = [];
        var keys:Vector<Null<Int>> = new Vector(size);
        var values:Vector<V> = new Vector(size);

        for (key in object.keys()) {
            var hash = hash(0, key);
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
                slot = (hash(d, bucket[item]) % size);
                
                if (values[slot] != null || (#if !static used[slot] != null && #end used[slot] == true)) {
                    d++;
                    item = 0;
                    slots = [];
                    used = [];

                } else {
                    used[slot] = true;
                    slots.push(slot);
                    item++;

                }

            }

            keys[(hash(0, bucket[0]) % size)] = d;

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

            keys[(hash(0, bucket[0]) % size)] = 0-slot-1;
            values[slot] = object.get(bucket[0]);

            i++;

        }

        return {keys: keys, values: values};
    }

    public function get<V>(table:Table<Int, V>, key:String):V {
        var d = table.keys[(hash(0, key) % table.keys.length)];
        if (d < 0) return table.values[0-d-1];
        return table.values[(hash(d, key) % table.values.length)];
    }

}