iOS host files for the INET Flutter starter.

This starter originally ships without a generated iOS host project.
If you are wiring this into a fresh clone, run:

flutter create . --platforms=android,ios

Then merge these files into the generated Runner target and add a Packet Tunnel extension target named `PacketTunnel` in Xcode.
Update bundle identifiers if your app does not use the default Flutter identifiers.
