import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:upload_files/bloc/file_list_bloc.dart';
import 'package:upload_files/bloc/file_state.dart';
import 'package:upload_files/screen/file_list_screen.dart';


class MainScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {



  final FileListScreen screen = FileListScreen();

  void _navToFileListScreen(FileListBloc bloc) async {

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext screenContext) => BlocProvider.value(
          child: screen,
          value: BlocProvider.of<FileListBloc>(context),
        ),
      ),
    );
  }

  void pressedReset() {

  }

  void _pressedSave() {
    context.read<FileListBloc>().add(FileStatusEvent.save);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Файлы сохранены')
    ));
  }

  @override
  Widget build(BuildContext context) {

    final FileListBloc bloc = BlocProvider.of(context);

    return Scaffold(
        appBar: AppBar(
          title: Text('Home page'),
        ),
        body: Container(
          child: ListTile(
              title: Text("Файлы"),
              trailing: Icon(Icons.arrow_forward_ios),
              subtitle: BlocBuilder<FileListBloc, FileState>(
                builder: (bloc1, state) {
                  String result = '';
                  if (state.files.length > 0 && state.filesLoading == 0) {
                    result = 'Кол-во файлов: '+state.files.length.toString();
                  } else {
                    result = 'Осталось загрузить: '
                        + state.filesLoading.toString()
                        +'. Всего файлов: '+state.files.length.toString();
                  }
                  if (state.files.length == 0 && state.filesLoading == 0) {
                    result = 'Нет файлов';
                  }
                  return Text(result);
                },
              ),
              onTap: () => { _navToFileListScreen(bloc) }
          ),
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            TextButton(
              child: Text('Сбросить'),
              onPressed: context.select((FileListBloc bloc) => bloc.canReset())
                  ? (){ context.read<FileListBloc>().add(FileStatusEvent.clear); } : null,
            ),
            TextButton(
              child: Text('Сохранить'),
              onPressed: context.select((FileListBloc bloc) => bloc.canSave())
                  ? _pressedSave : null,
            )
          ],
        )
    );
  }
}