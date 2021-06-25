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

    final CancelableCompleter<bool> _completer = CancelableCompleter(onCancel: () => false);

    Map <String, int> _files = {};
    Map <String, int> _filesLoadingQueue = {};
    List <String> _filesWaiting = [];
    String _uid;

    List<Future> eventQueue = [];
    BuiltMap<String, CancelableOperation> _queueOperations = BuiltMap();

    FileListBloc() : super(FileState({},0));

    Random random = new Random();


    @override
    Stream <FileState> mapEventToState(FileStatusEvent event) async* {

      switch (event) {
        case FileStatusEvent.initial:
          _uid = UniqueKey().toString();
          _files[_uid] = _FILE_WAITING;
          _filesWaiting.add(_uid);
          uploadFiles();
          break;
        case FileStatusEvent.clear:
          _filesLoadingQueue = {};
          _filesWaiting = [];
          _queueOperations.forEach((id, cancelableOperation) => cancelableOperation.cancel());
          _queueOperations = BuiltMap();
          _files = {};

          break;
        case FileStatusEvent.save:
          break;

      }
      yield FileState(_files, getLoadingCount());

    }
    Future getLoadingFiles() {
      return Future.value(_filesLoadingQueue.length);
    }

    Future uploadFiles() async {

      while (_filesWaiting.length > 0) {

        for (var i=0; i<_MAX_LOADING_FILE; i++) {

          if (_filesWaiting.length > i && _filesLoadingQueue.length  < _MAX_LOADING_FILE) {
            _files[_filesWaiting[i]] = _FILE_LOADING;
            _filesLoadingQueue[_filesWaiting[i]] = 0;
            _filesWaiting.remove(_filesWaiting[i]);
          }
        }
        _filesLoadingQueue.forEach((key, element)  {
            uploadFile(key);
        });
        if (_filesLoadingQueue.length == _MAX_LOADING_FILE) {
            await uploadFile(_filesLoadingQueue.keys.first);
        }
      }
    }

    Future uploadFile(String id) async {
      print(id);
      int randomNumber = random.nextInt(10);
      CancelableOperation cancelableOperation = CancelableOperation.fromFuture(
        Future.delayed(Duration(seconds: randomNumber)),
        onCancel: () => _cancelled(id),
      );
      _queueOperations = _queueOperations.rebuild((operations) => operations[id] = cancelableOperation);
      cancelableOperation.value.then((_) {
        if (_files[id] != null) {
          _files[id] = _FILE_LOADED;
          _filesLoadingQueue[id] = 1;
          _filesLoadingQueue.remove(id);
        }
        emit(FileState(_files, getLoadingCount()));
      });
      return cancelableOperation.valueOrCancellation();
    }

    int getLoadingCount() {
      List<int> keys = _files.values.where((value) => value ==_FILE_WAITING  || value == _FILE_LOADING ).toList();
      return keys.length;
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
      return _files.length > 0 && _filesLoadingQueue.length == 0;
    }


    @override
    Future<void> close() {
      return super.close();
    }

    _cancelled(String id) {
      _queueOperations = _queueOperations.rebuild((ops) => ops.remove(id));
    }

}

