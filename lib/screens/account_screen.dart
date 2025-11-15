import 'package:flutter/material.dart';

class ProfileCheck extends StatefulWidget {
	const ProfileCheck({super.key});
	@override
	ProfileState createState() => ProfileState();
}

class ProfileState extends State<ProfileCheck> {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			body: SafeArea(
				child: Container(
					constraints: const BoxConstraints.expand(),
					color: const Color(0xFFFFFFFF),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Expanded(
								child: IntrinsicHeight(
									child: Container(
										color: const Color(0xFFFFFFFF),
										width: double.infinity,
										height: double.infinity,
										child: SingleChildScrollView(
											child: Column(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( top: 55, bottom: 29, left: 13, right: 13),
															width: double.infinity,
															child: Row(
																mainAxisAlignment: MainAxisAlignment.spaceBetween,
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	// --- BACK BUTTON IMPLEMENTATION (Wrapped in GestureDetector) ---
																	GestureDetector(
																		onTap: () {
																			// This is the "nav bar back function from inventory.dart" 
																			// It uses pop() to return to the previous screen (Inventory).
																			Navigator.pop(context);
																		},
																		child: Container(
																			width: 34,
																			height: 34,
																			child: Image.network(
																				"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/6bc29b20-1e66-4229-9b29-5eebc21437b4",
																				fit: BoxFit.fill,
																			)
																		),
																	),
																	// --- END BACK BUTTON IMPLEMENTATION ---
																	
																	Container(
																		margin: const EdgeInsets.only( top: 2),
																		child: const Text(
																			"Account",
																			style: TextStyle(
																				color: Color(0xFF000000),
																				fontSize: 30,
																				fontWeight: FontWeight.bold,
																			),
																		),
																	),
																	Container(
																		width: 34,
																		height: 34,
																		child: const SizedBox(),
																	),
																]
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 65),
															width: double.infinity,
															child: Column(
																children: [
																	Container(
																		width: 100,
																		height: 100,
																		child: Image.network(
																			"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/e2ba4455-b670-4b25-83d8-f25d34e07bfa",
																			fit: BoxFit.fill,
																		)
																	),
																	const Text(
																		"Tap to add or change photo",
																		style: TextStyle(
																			color: Color(0xFF404040), 
																			fontSize: 14,
																		),
																	),
																]
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 20, left: 23),
														child: const Text(
															"Name",
															style: TextStyle(
																color: Color(0xFF000000),
																fontSize: 20,
																fontWeight: FontWeight.bold,
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																border: Border.all(
																	color: const Color(0xFF5C8A94),
																	width: 2,
																),
																borderRadius: BorderRadius.circular(20),
															),
															padding: const EdgeInsets.only( top: 6, bottom: 6, left: 15, right: 15),
															margin: const EdgeInsets.only( bottom: 27, left: 19, right: 19),
															width: double.infinity,
															child: Row(
																mainAxisAlignment: MainAxisAlignment.spaceBetween,
																children: [
																	const Text(
																		"Hidethepain Harold Harold",
																		style: TextStyle(
																			color: Color(0xFF404040),
																			fontSize: 18,
																			fontWeight: FontWeight.bold,
																		),
																	),
																	Container(
																		width: 25,
																		height: 25,
																		child: Image.network(
																			"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/6c7b3e7e-f0b0-4b34-bb3d-d4b8ff7207a7",
																			fit: BoxFit.fill,
																		)
																	),
																]
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 20, left: 23),
														child: const Text(
															"Email",
															style: TextStyle(
																color: Color(0xFF000000),
																fontSize: 20,
																fontWeight: FontWeight.bold,
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																border: Border.all(
																	color: const Color(0xFF5C8A94),
																	width: 2,
																),
																borderRadius: BorderRadius.circular(20),
															),
															padding: const EdgeInsets.only( top: 12, bottom: 12, left: 15),
															margin: const EdgeInsets.only( bottom: 27, left: 19, right: 19),
															width: double.infinity,
															child: const Column(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Text(
																		"abc@gmail.com",
																		style: TextStyle(
																			color: Color(0xFF404040),
																			fontSize: 18,
																			fontWeight: FontWeight.bold,
																		),
																	),
																]
															),
														),
													),
													Container(
														margin: const EdgeInsets.only( bottom: 20, left: 27),
														child: const Text(
															"Password",
															style: TextStyle(
																color: Color(0xFF000000),
																fontSize: 20,
																fontWeight: FontWeight.bold,
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																border: Border.all(
																	color: const Color(0xFF5C8A94),
																	width: 2,
																),
																borderRadius: BorderRadius.circular(20),
															),
															padding: const EdgeInsets.only( top: 6, bottom: 6, left: 15, right: 15),
															margin: const EdgeInsets.only( bottom: 71, left: 23, right: 23),
															width: double.infinity,
															child: Row(
																mainAxisAlignment: MainAxisAlignment.spaceBetween,
																children: [
																	const Text(
																		"********",
																		style: TextStyle(
																			color: Color(0xFF000000),
																			fontSize: 18,
																			fontWeight: FontWeight.bold,
																		),
																	),
																	Container(
																		width: 25,
																		height: 25,
																		child: Image.network(
																			"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/9e34e3f4-327c-4bae-a1ca-cd314a0a4bbd",
																			fit: BoxFit.fill,
																		)
																	),
																]
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															margin: const EdgeInsets.only( bottom: 48),
															width: double.infinity,
															child: Column(
																children: [
																	InkWell(
																		onTap: () { debugPrint('Save Pressed'); },
																		child: IntrinsicWidth(
																			child: IntrinsicHeight(
																				child: Container(
																					decoration: BoxDecoration(
																						borderRadius: BorderRadius.circular(51),
																						color: const Color(0xFF5C8A94),
																					),
																					padding: const EdgeInsets.only( top: 18, bottom: 18, left: 64, right: 64),
																					child: const Column(
																						crossAxisAlignment: CrossAxisAlignment.start,
																						children: [
																							Text(
																								"Save",
																								style: TextStyle(
																									color: Color(0xFFFFFFFF),
																									fontSize: 23,
																								),
																							),
																						]
																					),
																				),
																			),
																		),
																	),
																]
															),
														),
													),
													IntrinsicHeight(
														child: Container(
															decoration: BoxDecoration(
																border: Border.all(
																	color: const Color(0xFFF3F3F3),
																	width: 1,
																),
																color: const Color(0xFFFFFFFF),
															),
															padding: const EdgeInsets.symmetric(vertical: 21),
															width: double.infinity,
															child: Row(
																crossAxisAlignment: CrossAxisAlignment.start,
																children: [
																	Expanded(
																		child: Container(
																			margin: const EdgeInsets.only( left: 21, right: 48),
																			height: 30,
																			width: double.infinity,
																			child: Image.network(
																				"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/003a3863-122d-4130-9b28-721c017c860f",
																				fit: BoxFit.fill,
																			)
																		),
																	),
																	Expanded(
																		child: Container(
																			margin: const EdgeInsets.only( right: 43),
																			height: 30,
																			width: double.infinity,
																			child: Image.network(
																				"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/952b73a5-1eee-44ae-aacf-ce37ac6d3ef3",
																				fit: BoxFit.fill,
																			)
																		),
																	),
																	Expanded(
																		child: Container(
																			margin: const EdgeInsets.only( right: 43),
																			height: 30,
																			width: double.infinity,
																			child: Image.network(
																				"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/f7a11952-b3d9-4b51-ae13-a8253afa6161",
																				fit: BoxFit.fill,
																			)
																		),
																	),
																	Expanded(
																		child: IntrinsicHeight(
																			child: Container(
																				padding: const EdgeInsets.symmetric(vertical: 1),
																				margin: const EdgeInsets.only( right: 38),
																				width: double.infinity,
																				child: Column(
																					children: [
																						Container(
																							width: 27,
																							height: 27,
																							child: Image.network(
																								"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/cfd00384-0bbd-43ce-b737-2a75c7dc81f5",
																								fit: BoxFit.fill,
																							)
																						),
																					]
																				),
																			),
																		),
																	),
																	Expanded(
																		child: Container(
																			margin: const EdgeInsets.only( right: 32),
																			height: 30,
																			width: double.infinity,
																			child: Image.network(
																				"https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/3634f056-7b6a-4a52-a04f-2506f03927e1",
																				fit: BoxFit.fill,
																			)
																		),
																	),
																]
															),
														),
													),
												],
											)
										),
									),
								),
							),
						],
					),
				),
			),
		);
	}
}