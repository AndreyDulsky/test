import 'dart:async';
import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:built_collection/built_collection.dart';
import 'dart:math';
import 'file_state.dart';



enum FileStatusEvent { initial, waiting, loading, loaded, deleted, clear, save }

class FileListBloc extends Bloc<FileStatusEvent, FileState> {
  static const int _FILE_WAITING = 1;
  static const int _FILE_LOADING = 2;
  static const int _FILE_LOADED = 3;

  static const int _MAX_LOADING_FILE = 3;
  static const int _MAX_FILES = 30;

  Map <String, int> _files = {};

  String _uid;

  BuiltMap<String, CancelableOperation> _queueOperations = BuiltMap();
  StreamSubscription subscription;

  FileListBloc() : super(FileState({},0)) {
    subscription = streamFiles.listen((stateB) {
      queueHandler();
    });
  }
  Stream<Map <String, int>> get streamFiles {
    return _controller.stream.asBroadcastStream();
  }

  StreamController _controller = StreamController<Map <String, int>>();

  int countLoading;

  Random random = new Random();


  @override
  Stream <FileState> mapEventToState(FileStatusEvent event) async* {

    switch (event) {
      case FileStatusEvent.initial:
        _uid = UniqueKey().toString();
        _files[_uid] = _FILE_WAITING;
        _controller.sink.add(_files);
        break;
      case FileStatusEvent.clear:
        _queueOperations.forEach((id, cancelableOperation) => cancelableOperation.cancel());
        _queueOperations = BuiltMap();
        _files = {};

        break;
      case FileStatusEvent.save:
        break;

    }
    yield FileState(_files, getLoadingCount());

  }

  void queueHandler() async {

    Map<String,int> resultLoading = getLoadingFiles();
    Map<String,int> resultWaiting = getWaitingFiles();

    while (resultWaiting.length != 0 && resultLoading.length < _MAX_LOADING_FILE) {
      uploadFile(resultWaiting.keys.first);
      resultLoading = getLoadingFiles();
      resultWaiting = getWaitingFiles();
    }
  }

  Future uploadFile(String id) async {
    _files[id] = _FILE_LOADING;
    int randomNumber = random.nextInt(5);
    CancelableOperation cancelableOperation = CancelableOperation.fromFuture(
      Future.delayed(Duration(seconds: randomNumber)),
      onCancel: () => _cancelled(id),
    );

    _queueOperations = _queueOperations.rebuild((operations) => operations[id] = cancelableOperation);
    cancelableOperation.value.then((_) {
      if (_files[id] != null) {
        _files[id] = _FILE_LOADED;
        _controller.sink.add(_files);
      }
      emit(FileState(_files, getLoadingCount()));
    });
    return cancelableOperation.valueOrCancellation();
  }

  int getLoadingCount() {
    List<int> keys = _files.values.where((value) => value ==_FILE_WAITING  || value == _FILE_LOADING ).toList();
    return keys.length;
  }

  getWaitingFiles() {
    Map<String, int> keys = {};
    _files.forEach((key, value) {
      if (value == _FILE_WAITING) {
        keys[key] = value;
      }
    });
    //_controller.sink.add(keys);
    return keys;
  }

  getLoadingFiles() {
    Map<String, int> keys = {};
    _files.forEach((key, value) {
      if (value == _FILE_LOADING) {
        keys[key] = value;
      }
    });
    //_controller.sink.add(keys);
    return keys;
  }

  void deleted(String id) {
    _files.remove(id);
    _cancelled(id);
    emit(FileState(_files, getLoadingCount()));
  }

  bool isMaxLength() {
    return (_files.length == _MAX_FILES);
  }

  bool canReset() {
    return _files.length > 0;
  }

  bool canSave() {
    return _files.length > 0 && getLoadingFiles().length == 0;
  }


  @override
  Future<void> close() {
    _controller.close();
    return super.close();
  }

  _cancelled(String id) {
    _queueOperations = _queueOperations.rebuild((ops) => ops.remove(id));
  }

}

