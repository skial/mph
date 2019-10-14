# mph
Minimal Perfect Hashing

> Based on the article [Throw away the keys: Easy, Minimal Perfect Hashing](http://stevehanov.ca/blog/?id=119).

## Install

- `lix install gh:skial/mph`

## Example

```Haxe
package ;

import hash.*;

class Entry {

    public static function main() {
        var map = ['a'=>'A', 'b'=>'B', 'cCCCC'=>'C'];
        var hash = new Mph();
        var table = hash.build(map, Mph.HashString, 3);
        
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
    }

}
```

### Notes

Help from:
    - [perfect](https://github.com/mixu/perfect)
    - [mph](https://github.com/ChrisTrenkamp/mph)