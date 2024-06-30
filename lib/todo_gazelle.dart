import 'dart:convert';
import 'package:gazelle_core/gazelle_core.dart';
import 'package:todo_gazelle/entities/todo.dart';
import 'package:uid/uid.dart';

Future<void> runApp(List<String> args) async {
  final todos = <Todo>[];

  final app = GazelleApp(address: 'localhost', port: 8080, routes: [
    GazelleRoute(
      name: 'todo',
      children: [
        GazelleRoute.parameter(
          name: 'id',
          // GET /todo/:id -> Get a todo by ID
          get: (context, request, response) async {
            final id = request.pathParameters['id'];
            if (id == null) {
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.badRequest_400,
                  body: 'ID is required.');
            }

            try {
              final todo = todos.firstWhere((todo) => todo.id == id);
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.success.ok_200,
                  body: jsonEncode(todo));
            } catch (e) {
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.notFound_404,
                  body: 'Todo not found.');
            }
          },
          // PUT /todo/:id -> Update a todo by ID
          put: (context, request, response) async {
            final id = request.pathParameters['id'];
            final data = jsonDecode(await request.body ?? "{}");

            if (id == null) {
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.badRequest_400,
                  body: 'ID is required.');
            }

            try {
              final todo = todos.firstWhere((todo) => todo.id == id);

              todo.title = data["title"] ?? todo.title;
              todo.description = data["description"] ?? todo.description;
              todo.completed = data["completed"] ?? todo.completed;
              todo.completedAt = data["completedAt"] != null
                  ? DateTime.parse(data["completedAt"])
                  : todo.completedAt;

              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.success.ok_200,
                  body: jsonEncode(todo));
            } catch (e) {
              print(e);
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.notFound_404,
                  body: 'Todo not found.');
            }
          },
          // DELETE /todo/:id -> Delete a todo by ID
          delete: (context, request, response) async {
            final id = request.pathParameters['id'];
            if (id == null) {
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.badRequest_400,
                  body: 'ID is required.');
            }

            try {
              final todo = todos.firstWhere((todo) => todo.id == id);
              todos.remove(todo);

              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.success.ok_200,
                  body: jsonEncode(todo));
            } catch (e) {
              return GazelleResponse(
                  statusCode: GazelleHttpStatusCode.error.notFound_404,
                  body: 'Todo not found.');
            }
          },
        ),
      ],
      // GET /todo -> Get all todos
      get: (context, request, response) => GazelleResponse(
          statusCode: GazelleHttpStatusCode.success.ok_200,
          body: jsonEncode(todos)),
      // POST /todo -> Create a new todo
      post: (context, request, response) async {
        final data = jsonDecode(await request.body ?? "{}");

        if (data["title"] == null) {
          return GazelleResponse(
              statusCode: GazelleHttpStatusCode.error.badRequest_400,
              body: 'Title is required.');
        }

        try {
          final todo = Todo(
              id: UId.getId(),
              title: data["title"],
              description: data["description"] ?? "",
              completed: data["completed"] ?? false,
              createdAt: DateTime.now(),
              completedAt: data["completedAt"] != null
                  ? DateTime.parse(data["completedAt"])
                  : null);

          todos.add(todo);

          return GazelleResponse(
              statusCode: GazelleHttpStatusCode.success.created_201,
              body: jsonEncode(todo));
        } catch (e) {
          return GazelleResponse(
              statusCode: GazelleHttpStatusCode.error.internalServerError_500,
              body: 'Failed to create todo.');
        }
      },
    )
  ]);

  await app.start();
  print("Gazelle listening at ${app.serverAddress}");
}
