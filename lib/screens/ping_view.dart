// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_icmp_ping/flutter_icmp_ping.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:network_arch/models/ping_model.dart';
import 'package:network_arch/services/utils/keyboard_hider.dart';
import 'package:network_arch/services/widgets/builders.dart';
import 'package:network_arch/services/widgets/shared_widgets.dart';

class PingView extends StatefulWidget {
  const PingView({Key? key}) : super(key: key);

  @override
  _PingViewState createState() => _PingViewState();
}

class _PingViewState extends State<PingView> {
  final targetHostController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    targetHostController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PingModel pingModel = Provider.of<PingModel>(context);

    return Scaffold(
      appBar: pingModel.isPingingStarted
          ? Builders.switchableAppBar(
              context: context,
              title: 'Ping',
              action: ButtonActions.stop,
              isActive: true,
              onPressed: () {
                setState(() {
                  pingModel.stopStream();
                  pingModel.isPingingStarted = false;
                });
              },
            )
          : Builders.switchableAppBar(
              context: context,
              title: 'Ping',
              action: ButtonActions.start,
              isActive: targetHostController.text.isNotEmpty,
              onPressed: () {
                setState(() {
                  pingModel.clearData();
                  pingModel.setHost(
                    targetHostController.text.isEmpty
                        ? null
                        : targetHostController.text,
                  );
                  pingModel.isPingingStarted = true;
                });

                targetHostController.clear();
                hideKeyboard(context);
              },
            ),
      body: SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: targetHostController,
                      autocorrect: false,
                      enabled: !pingModel.isPingingStarted,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                        labelText: 'IP address (e.g. 1.1.1.1)',
                      ),
                      onChanged: (_) {
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
            ),
            Consumer<PingModel>(
              builder: (context, model, child) {
                if (model.isPingingStarted) {
                  return StreamBuilder(
                    stream: model.getStream(),
                    initialData: null,
                    builder: (context, AsyncSnapshot<PingData?> snapshot) {
                      if (snapshot.hasError) {
                        // print(snapshot.error);
                      }

                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      } else {
                        model.pingData.add(snapshot.data);

                        return buildPingListView(model);
                      }
                    },
                  );
                } else {
                  return buildPingListView(model);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Padding buildPingListView(PingModel model) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: model.pingData.length,
        itemBuilder: (context, index) {
          final PingData currData = model.pingData[index]!;

          if (currData.error != null) {
            return Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                leading: const StatusCard(
                  color: CupertinoColors.systemRed,
                  text: 'Error',
                ),
                title: Text(model.getHost ?? 'N/A'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seq. pos.: ${index + 1}'),
                    const Text('TTL: N/A'),
                  ],
                ),
                trailing: SizedBox(
                  width: 110,
                  child: Text(
                    model.getErrorDesc(currData.error!),
                  ),
                ),
              ),
            );
          }

          if (currData.response != null) {
            return Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: ListTile(
                leading: const StatusCard(
                  color: CupertinoColors.systemGreen,
                  text: 'Online',
                ),
                title: Text(currData.response!.ip!),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Seq. pos.: ${currData.response!.seq.toString()} '),
                    Text('TTL: ${currData.response!.ttl.toString()}')
                  ],
                ),
                trailing: Text(
                  '${currData.response!.time!.inMilliseconds.toString()} ms',
                ),
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}
