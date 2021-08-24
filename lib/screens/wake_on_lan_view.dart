// Flutter imports:
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:network_arch/constants.dart';
import 'package:network_arch/services/utils/enums.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:network_arch/models/wake_on_lan_model.dart';
import 'package:network_arch/services/widgets/shared_widgets.dart';

class WakeOnLanView extends StatefulWidget {
  const WakeOnLanView({Key? key}) : super(key: key);

  @override
  _WakeOnLanViewState createState() => _WakeOnLanViewState();
}

class _WakeOnLanViewState extends State<WakeOnLanView> {
  final ipv4TextFieldController = TextEditingController();
  final macTextFieldController = TextEditingController();

  bool areTextFieldsNotEmpty() {
    return ipv4TextFieldController.text.isNotEmpty &&
        macTextFieldController.text.isNotEmpty;
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    ipv4TextFieldController.dispose();
    macTextFieldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wake on LAN'),
        iconTheme: Theme.of(context).iconTheme,
        textTheme: Theme.of(context).textTheme,
        actions: [
          TextButton(
            onPressed: !areTextFieldsNotEmpty()
                ? null
                : () async {
                    final model = context.read<WakeOnLanModel>();

                    model.ipv4 = ipv4TextFieldController.text;
                    model.mac = macTextFieldController.text;

                    if (model.areTextFieldsValid()) {
                      await model.sendPacket();
                    } else {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(Constants.wolValidationFault);
                    }
                  },
            child: Text(
              'Send',
              style: TextStyle(
                color: areTextFieldsNotEmpty() ? Colors.green : Colors.grey,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              TextField(
                autocorrect: false,
                controller: ipv4TextFieldController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  labelText: 'IPv4 address',
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              TextField(
                autocorrect: false,
                controller: macTextFieldController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  labelText: 'MAC address',
                ),
                onChanged: (_) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 10),
              buildResponsesView(context),
            ],
          ),
        ),
      ),
    );
  }

  ListView buildResponsesView(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: context.watch<WakeOnLanModel>().wolResponses.length,
      itemBuilder: (context, index) {
        final WolResponse response =
            context.read<WakeOnLanModel>().wolResponses[index];

        return Card(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 5.0),
            leading: response.status == WolStatus.success
                ? const StatusCard(text: 'Success', color: Colors.green)
                : const StatusCard(text: 'Fail', color: Colors.red),
            title: Text('IP: ${response.ipv4}'),
            subtitle: Text('MAC: ${response.mac}'),
            trailing: TextButton(
              onPressed: response.status == WolStatus.success
                  ? () {
                      // TODO: Pass address to the ping tool.

                      Navigator.popAndPushNamed(
                        context,
                        '/tools/ping',
                        arguments: response.ipv4,
                      );
                    }
                  : null,
              child: const Text('Ping address'),
            ),
          ),
        );
      },
    );
  }
}
