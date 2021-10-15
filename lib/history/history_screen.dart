/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:dart_git/git.dart';
import 'package:dart_git/plumbing/commit_iterator.dart';
import 'package:dart_git/plumbing/objects/commit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:gitjournal/generated/locale_keys.g.dart';
import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/repository.dart';
import 'commit_data_widget.dart';

class HistoryScreen extends StatelessWidget {
  static const String routePath = "/history";

  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var gjRepo = Provider.of<GitJournalRepo>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.drawer_history.tr()),
      ),
      body: HistoryWidget(repoPath: gjRepo.repoPath),
    );
  }
}

class HistoryWidget extends StatefulWidget {
  final String repoPath;

  const HistoryWidget({Key? key, required this.repoPath}) : super(key: key);

  @override
  _HistoryWidgetState createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  List<Result<GitCommit>> commits = [];
  Stream<Result<GitCommit>>? _stream;

  final _scrollController = ScrollController();
  final _lock = Lock();

  Exception? _exception;
  GitRepository? _gitRepo;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });

    _loadMore();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _loadMore() async {
    print('load more ...');

    // This needs to happen in another thread!
    await _lock.synchronized(() async {
      _stream ??= await _initStream();
      var stream = _stream!;

      var list = <Result<GitCommit>>[];
      for (var j = 0; j < 20; j++) {
        await for (var commit in stream) {
          // FIXME: Does this even work to load it gradually?
          list.add(commit);
        }
      }

      setState(() {
        commits.addAll(list);
      });
    });
  }

  Future<Stream<Result<GitCommit>>> _initStream() async {
    print('initializing the stream?');
    try {
      _gitRepo = await GitRepository.load(widget.repoPath).getOrThrow();
      var head = await _gitRepo!.headHash().getOrThrow();
      return commitPreOrderIterator(
              objStorage: _gitRepo!.objStorage, from: head)
          .asBroadcastStream();
    } on Exception catch (ex) {
      setState(() {
        _exception = ex;
      });
    }

    return const Stream.empty();
  }

  @override
  Widget build(BuildContext context) {
    if (_exception != null) {
      return _FailureTile(result: Result.fail(_exception!));
    }

    return Scrollbar(
      child: ListView.builder(
        controller: _scrollController,
        itemBuilder: _buildTile,
        itemCount: commits.length,
      ),
    );
  }

  Widget _buildTile(BuildContext context, int i) {
    if (i >= commits.length) {
      return const CircularProgressIndicator();
    }

    if (i == commits.length - 1) {
      var result = commits[i];
      return result.isSuccess
          ? _CommitTile(
              commit: result.getOrThrow(),
              prevCommit: null,
              gitRepo: _gitRepo!,
            )
          : _FailureTile(result: result);
    }

    try {
      return _CommitTile(
        gitRepo: _gitRepo!,
        commit: commits[i].getOrThrow(),
        prevCommit: commits[i + 1].getOrThrow(),
      );
    } on Exception catch (ex, st) {
      return _FailureTile(result: Result.fail(ex, st));
    }
  }
}

class _CommitTile extends StatefulWidget {
  final GitRepository gitRepo;
  final GitCommit commit;
  final GitCommit? prevCommit;

  const _CommitTile({
    Key? key,
    required this.gitRepo,
    required this.commit,
    required this.prevCommit,
  }) : super(key: key);

  @override
  State<_CommitTile> createState() => _CommitTileState();
}

class _CommitTileState extends State<_CommitTile> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    var msgLines = LineSplitter.split(widget.commit.message).toList();
    var title = msgLines.first;

    var textTheme = Theme.of(context).textTheme;

    Locale locale = Localizations.localeOf(context);
    var when =
        timeago.format(widget.commit.author.date, locale: locale.languageCode);

    Widget body = Row(
      children: <Widget>[
        Expanded(
          child: Text(title, style: textTheme.subtitle2!),
        ),
        Text(when, style: textTheme.caption)
      ],
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
    );

    if (expanded && widget.prevCommit != null) {
      body = Column(
        children: [
          body,
          CommitDataWidget(
            gitRepo: widget.gitRepo,
            commit: widget.commit,
            prevCommit: widget.prevCommit!,
          ),
        ],
      );
    }

    return GestureDetector(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: body,
        ),
      ),
      onTap: () {
        setState(() {
          expanded = !expanded;
        });
      },
    );
  }
}

class _FailureTile<T> extends StatelessWidget {
  final Result<T> result;

  _FailureTile({Key? key, required this.result}) : super(key: key) {
    Log.e("Failure", ex: result.error, stacktrace: result.stackTrace);
  }

  @override
  Widget build(BuildContext context) {
    return Text(result.error.toString());
  }
}

// Extra info -
// * Has this commit been pushed, failed to sync
// * Title
// * (rest of the message - optionally)
// * Time
// * Author
// * Files + changes

// class _ExpandedCommitTile extends StatelessWidget {
//   const _ExpandedCommitTile({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container();
//   }
// }

// * Do a diff of files changed
// * Show added / removed easily
// * Show modified with a kind of whatever
