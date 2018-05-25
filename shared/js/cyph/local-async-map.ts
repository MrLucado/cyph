import {Observable} from 'rxjs';
import {map} from 'rxjs/operators';
import {IAsyncMap} from './iasync-map';
import {LocalAsyncValue} from './local-async-value';
import {LockFunction} from './lock-function-type';
import {getOrSetDefault} from './util/get-or-set-default';
import {lockFunction} from './util/lock';


/**
 * IAsyncMap implementation that wraps a local value.
 */
export class LocalAsyncMap<K, V> extends LocalAsyncValue<Map<K, V>> implements IAsyncMap<K, V> {
	/** @inheritDoc */
	private readonly locks: Map<K, LockFunction>	= new Map<K, LockFunction>();

	/** @inheritDoc */
	public async clear () : Promise<void> {
		this.value.clear();
	}

	/** @inheritDoc */
	public async getItem (key: K) : Promise<V> {
		if (!this.value.has(key)) {
			throw new Error(`No item ${key} in async map.`);
		}

		return <V> this.value.get(key);
	}

	/** @inheritDoc */
	public async getKeys () : Promise<K[]> {
		return Array.from(this.value.keys());
	}

	/** @inheritDoc */
	public async hasItem (key: K) : Promise<boolean> {
		return this.value.has(key);
	}

	/** @inheritDoc */
	public async removeItem (key: K) : Promise<void> {
		this.value.delete(key);
	}

	/** @inheritDoc */
	public async setItem (key: K, value: V) : Promise<void> {
		this.value.set(key, value);
	}

	/** @inheritDoc */
	public async size () : Promise<number> {
		return this.value.size;
	}

	/** @inheritDoc */
	public async updateItem (key: K, f: (value?: V) => Promise<V>) : Promise<void> {
		await getOrSetDefault(this.locks, key, lockFunction)(async () => {
			const value	= await this.getItem(key).catch(() => undefined);
			let newValue: V;
			try {
				newValue	= await f(value);
			}
			catch {
				return;
			}
			await this.setItem(key, newValue);
		});
	}

	/** @inheritDoc */
	public watchSize () : Observable<number> {
		return this.watch().pipe(map(value => value.size));
	}

	constructor (value?: Map<K, V>) {
		super(value || new Map<K, V>());
	}
}
