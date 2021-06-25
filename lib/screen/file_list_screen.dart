import 'package:flutter/material.dart';
import 'package:upload_files/bloc/file_list_bloc.dart';
import 'package:upload_files/bloc/file_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FileListScreen extends StatefulWidget {
  @override
  _FileListScreenState createState() => _FileListScreenState();
}

class _FileListScreenState extends State<FileListScreen> {

  static const Map<int,String> _FILE_STATUS = {
    1: 'В ожидании',
    2: 'Загружается',
    3: ''
  };

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
        appBar: AppBar(
          title: Text("Файлы"),
        ),
        body: Container(
          child: BlocBuilder<FileListBloc, FileState>(
            builder: (_, state) {
              if (state.files.length == 0) {
                return Text('Нет файлов');
              }
              return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.files.length,
                  itemBuilder: (BuildContext context, int index) {
                    String key = state.files.keys.elementAt(index);
                    return ListTile(
                        title: Text("Файл "+key),
                        trailing: Icon(Icons.delete),
                        subtitle: Text(_FILE_STATUS[state.files[key]]),
                        onTap: () => context.read<FileListBloc>().deleted(key)
                    );
                  }
              );

            },
          ),
        ),
        floatingActionButton:  Visibility(
          child: FloatingActionButton(
            onPressed: () =>  context.read<FileListBloc>().add(FileStatusEvent.initial),
            tooltip: 'Add file',
            child: Icon(Icons.add),
          ),
          visible: context.select((FileListBloc bloc) => !bloc.isMaxLength()),
        ),
    );
  }
}