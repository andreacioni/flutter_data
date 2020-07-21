part of flutter_data;

/// A mixin to "tag" and ensure the implementation of an [id] getter
/// in data classes managed through Flutter Data.
///
/// It contains private state and methods to track the data objects identity.
abstract class DataModel<T extends DataModel<T>> {
  Object get id;

  // "late" finals
  String _key;
  Map<String, RemoteAdapter> _adapters;

  // computed
  String get _type => DataHelpers.getType<T>();
  RemoteAdapter<T> get _adapter => _adapters[_type] as RemoteAdapter<T>;
  bool get _isInitialized => _key != null && _adapters != null;

  // initializers

  @protected
  T debugInit(dynamic repository) {
    assert(repository is Repository<T>);
    return _initialize((repository as Repository<T>)._adapters, save: true);
  }

  T _initialize(final Map<String, RemoteAdapter> adapters,
      {final String key, final bool save = false}) {
    if (_isInitialized) return _this;

    _this._adapters = adapters;

    assert(_adapter != null, '''\n
Please ensure the type `$T` has been correctly initialized.\n
''');

    // model.id could be null, that's okay
    _this._key = _adapter.graph.getKeyForId(_this._adapter.type, _this.id,
        keyIfAbsent: key ?? DataHelpers.generateKey<T>());

    if (save) {
      _adapter.localAdapter.save(_this._key, _this);
    }

    // initialize relationships
    for (final metadata
        in _adapter.localAdapter.relationshipsFor(_this).entries) {
      final relationship = metadata.value['instance'] as Relationship;

      relationship?.initialize(
        adapters: adapters,
        owner: _this,
        name: metadata.key,
        inverseName: metadata.value['inverse'] as String,
      );
    }

    return _this;
  }
}

/// Extension that adds syntax-sugar to data classes,
/// linking them to common [Repository] methods such as
/// [save] and [delete].
extension DataModelExtension<T extends DataModel<T>> on DataModel<T> {
  T get _this => this as T;

  /// Initializes a model copying the identity of supplied [model]
  ///
  /// Usage:
  /// ```
  /// final post = await repository.findOne('1'); // returns initialized post
  /// final newPost = Post(title: 'test'); // uninitialized post
  /// newPost.was(post); // new is now initialized with same key as post
  /// ```
  T was(T model) {
    assert(model != null && model._isInitialized,
        'Please initialize model before passing it to `was`');
    return _this._initialize(model._adapters, key: model._key, save: true);
  }

  /// Saves this data object through a call equivalent to [Repository.save]
  ///
  /// Usage: `await post.save()`, `author.save(remote: false, params: {'a': 'x'})`
  ///
  /// This data object MUST be initialized.
  Future<T> save(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    return await _adapter.save(_this,
        remote: remote, params: params, headers: headers, init: true);
  }

  /// Deletes this data object through a call equivalent to [Repository.delete]
  ///
  /// Usage: `await post.delete()`
  ///
  /// This data object MUST be initialized.
  Future<void> delete(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    await _adapter.delete(_this,
        remote: remote, params: params, headers: headers);
  }

  /// Re-fetch this data object through a call equivalent to [Repository.findOne]
  /// with the current object/[id]
  ///
  /// This data object MUST be initialized.
  Future<T> reload(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers}) async {
    return await _adapter.findOne(_this,
        remote: remote, params: params, headers: headers, init: true);
  }

  /// Watch this data object through a call equivalent to [Repository.watchOne]
  /// with the current object/[id]
  ///
  /// This data object MUST be initialized.
  DataStateNotifier<T> watch(
      {bool remote,
      Map<String, dynamic> params,
      Map<String, String> headers,
      AlsoWatch<T> alsoWatch}) {
    return _adapter.watchOne(_this,
        remote: remote, params: params, headers: headers, alsoWatch: alsoWatch);
  }
}

/// Returns a data object's `_key` private attribute.
///
/// Useful for testing, debugging or usage in [RemoteAdapter] subclasses
String keyFor<T extends DataModel<T>>(T model) => model?._key;