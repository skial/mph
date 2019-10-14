package hash;

import hash.Mph;
import tink.unit.Assert.*;

using StringTools;
using tink.CoreApi;

@:asserts
class MphSpec {

    public function new() {}

    public function tesString() {
        var max = 1234;
        var map:Map<String, Array<Int>> = [];
        var values:Array<Int> = [];

        for (i in 0...max) {
            var key = String.fromCharCode(i*32) + String.fromCharCode(i + Std.random(i));
            key += String.fromCharCode(i*32) + String.fromCharCode(i + Std.random(i));
            
            values.push(i);
            map.set( key, values.copy() );
        }

        var mph = new Mph();
        // Limit max attempts to `5` to reduce potential run time.
        var table = mph.build( map, Mph.HashString, max, 5 );

        // Testing `>=` instead of `==` because `mph.build` may increase the size to find a hash that works.
        asserts.assert( table.keys.length >= max );
        asserts.assert( table.keys.length == table.values.length );

        #if !(php  || eval || macro)
        // Runs into a stack overflow.
        var samples = [for (i in 0...Math.floor(max / 3)) Std.random(max)];
        samples.sort( (a, b) -> a - b );
        
        var index = 0;
        for (key => value in map) {
            if (samples.indexOf(index) > -1) {
                samples.pop();
                var tableValue = mph.get(table, key, Mph.HashString);
                var valueValue = value;
                asserts.assert( tableValue.length == valueValue.length );
                asserts.assert( tableValue[0] == valueValue[0] );
                asserts.assert( tableValue[tableValue.length - 1] == valueValue[tableValue.length - 1] );

            }
            index++;
        }
        #end

        return asserts.done();
    }

    public function testArray() {
        var max = 1234;
        var map:Map<Array<Int>, String> = [];
        var values:Array<Int> = [];

        for (i in 0...max) {
            var key = String.fromCharCode(Std.random(95)+32) + String.fromCharCode(i+32 + Std.random(95)+32);
            key += String.fromCharCode(Std.random(95)+32) + String.fromCharCode(i+32 + Std.random(95)+32);
            
            values.push(i);
            map.set( values.copy(), key );
        }

        var mph = new Mph();
        // Limit max attempts to `5` to reduce potential run time.
        var table = mph.build( map, Mph.HashArray, max, 5 );

        // Testing `>=` instead of `==` because `mph.build` may increase the size to find a hash that works.
        asserts.assert( table.keys.length >= max );
        asserts.assert( table.keys.length == table.values.length );

        #if !(neko || php || eval || macro)
        // Runs into a stack overflow.
        var samples = [for (i in 0...Math.floor(max / 3)) Std.random(max)];
        samples.sort( (a, b) -> a - b );
        
        var index = 0;
        for (key => value in map) {
            if (samples.indexOf(index) > -1) {
                samples.pop();
                var tableValue = mph.get(table, key, Mph.HashArray);
                var valueValue = value;
                asserts.assert( tableValue.length == valueValue.length );
                asserts.assert( tableValue == valueValue );

            }
            index++;
        }
        #end

        return asserts.done();
    }

    public function testJson() {
        var mph = new Mph();
        var json = Sys.getCwd() + '/res/entities.json';
        var data:haxe.DynamicAccess<{ codepoints:Array<Int>, characters:String }> = haxe.Json.parse( sys.io.File.getContent(json) );
        var map:Map<String, String> = [];
        var size = 0;

        for (key => value in data) {
            var _key = key.substring(1, key.length - 1);
            map.set( unifill.InternalEncoding.fromCodePoints(value.codepoints), _key );
            size++;
        }

        try {
            var table = mph.build(map, hash.Mph.HashString, size, 5);
            asserts.assert( table.keys.length >= size );
            asserts.assert( table.keys.length == table.values.length );

            #if !(php || eval || macro)
            // Runs into a stack overflow.
            var samples = [for (i in 0...Math.floor(size / 3)) Std.random(size)];
            samples.sort( (a, b) -> a - b );
            
            var index = 0;
            for (key => value in map) {
                if (samples.indexOf(index) > -1) {
                    samples.pop();
                    var tableValue = mph.get(table, key, Mph.HashString);
                    var valueValue = value;
                    asserts.assert( tableValue.length == valueValue.length );
                    asserts.assert( tableValue == valueValue );

                }
                index++;
            }
            #end

        } catch (e:Any) {
            trace(e);
            return asserts.fail('' + e);
        }

        return asserts.done();
    }

    public function testContainerCasting() {
        var left = ['a', 'b', 'c'];
        var right = ['AAA', 'BBB', 'CCC'];
        var pair:Pair<Array<String>, Array<String>> = new Pair(left, right);

        var mph = new Mph();
        var table = mph.build(pair, hash.Mph.HashString, left.length, 5);
        asserts.assert( table.keys.length >= left.length );
        asserts.assert( table.keys.length == table.values.length );

        for (i in 0...left.length) {
            var key = left[i];
            var value = right[i];
            asserts.assert( mph.get(table, key, hash.Mph.HashString) == value );
        }

        return asserts.done();
    }

}