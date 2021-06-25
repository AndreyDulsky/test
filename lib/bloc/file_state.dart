class FileState  {
  final Map<String, int> files;
  final int filesLoading;

  const FileState(this.files, this.filesLoading);

  List<Object> get props => [files, filesLoading];
}

