import 'node_file_storage_stub.dart' as stub;
import 'node_file_storage_io.dart'
    if (dart.library.html) 'node_file_storage_web.dart';

export 'node_file_storage_stub.dart' show NodeFileStorage;

stub.NodeFileStorage getNodeFileStorage() => createNodeFileStorage();
