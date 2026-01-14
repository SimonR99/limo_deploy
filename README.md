
# INF3995 usb key preparation


## Preparation

- Plug the usb key into your computer
- Ensure the usb key is named equipeXXX
- Ensure the format of the usb key is Ext4


## Running the script

- Plug the usb key into a robot
- Run the script

```bash
./deploy.sh equipeXXX lmXXX
```

where equipeXXX is the name of the usb key and lmXXX is the name of the robot

## Validation

To ensure that the usb key has correctly been copied, you can run the ros2 command :

```bash
ros2 launch limo_bringup limo_start.launch.py
```




