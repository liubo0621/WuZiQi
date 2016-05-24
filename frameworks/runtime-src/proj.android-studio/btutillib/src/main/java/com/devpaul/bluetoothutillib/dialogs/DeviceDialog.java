package com.devpaul.bluetoothutillib.dialogs;

import android.bluetooth.BluetoothDevice;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.AdapterView;
import android.widget.Button;
import android.widget.ListView;

import com.afollestad.materialdialogs.MaterialDialog;
import com.devpaul.bluetoothutillib.R;
import com.devpaul.bluetoothutillib.abstracts.BaseBluetoothActivity;
import com.devpaul.bluetoothutillib.broadcasts.BluetoothBroadcastReceiver;
import com.devpaul.bluetoothutillib.broadcasts.BluetoothStateReceiver;
import com.devpaul.bluetoothutillib.broadcasts.FoundDeviceReceiver;
import com.devpaul.bluetoothutillib.utils.BluetoothDeviceListAdapter;
import com.devpaul.bluetoothutillib.utils.BluetoothUtility;
import com.devpaul.bluetoothutillib.utils.SimpleBluetoothListener;

import java.util.ArrayList;
import java.util.List;

/**
 * Dialog for choosing a paired bluetooth device or scanning for new, available devices.
 */
public class DeviceDialog extends BaseBluetoothActivity implements FoundDeviceReceiver.FoundDeviceReceiverCallBack {

    /**
     * List view for the devices.
     */
    private ListView listView;

    /**
     * Utility that handles the bluetooth stuff.
     */
    private BluetoothUtility bluetoothUtility;

    /**
     * List of devices.
     */
    private List<BluetoothDevice> devices;

    /**
     * List adapter for the list view.
     */
    private BluetoothDeviceListAdapter bdla;

    /**
     * Broadcast receiver for bluetooth enabled.
     */
    private BluetoothBroadcastReceiver bluetoothBroadcastReceiver;

    /**
     * Broadcast receiver for when device is found during scan.
     */
    private FoundDeviceReceiver foundDeviceReceiver;

    /**
     * Broadcast receiver for changes in bluetooth states.
     */
    private BluetoothStateReceiver bluetoothStateReceiver;

    /**
     * Button that starts scanning.
     */
    private Button scanButton;

    /**
     * Constant name for retrieving bluetooth device from this activity in on activity result.
     */
    public static final String DEVICE_DIALOG_DEVICE_EXTRA = "deviceDialogDeviceExtra";

    /**
     * Constant name for retrieving bluetooth device address from this activity in on activity
     * result.
     */
    public static final String DEVICE_DIALOG_DEVICE_ADDRESS_EXTRA = "deviceDialogDeviceAddressExtra";

    /**
     * Progress Dialog that is shown during scanning.
     */
    private MaterialDialog progressDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        setContentView(R.layout.activity_bluetooth_dialog);
        //list view for all the items.
        listView = (ListView) findViewById(android.R.id.list);
        //start the bluetooth utility.
        //set up the button.
        scanButton = (Button) findViewById(R.id.scan_button);
        scanButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                getSimpleBluetooth().scan();
            }
        });
        super.onCreate(savedInstanceState);
    }

    @Override
    protected void onPostCreate(Bundle savedInstanceState) {
        super.onPostCreate(savedInstanceState);
        //prepare the progress dialog.
        prepareProgressDialog();
        //add items to the list.
        populateList();
    }

    /**
     * Helper method to prepare the progress dialog for showing.
     */
    private void prepareProgressDialog() {
        progressDialog = new MaterialDialog.Builder(this)
                .title("Please Wait")
                .content("Scanning")
                .progress(true, 0)
                .positiveText("Cancel")
                .callback(new MaterialDialog.ButtonCallback() {
                    @Override
                    public void onPositive(MaterialDialog dialog) {
                        if(bluetoothUtility != null) {
                            getSimpleBluetooth().cancelScan();
                            progressDialog.dismiss();
                        }
                    }
                })
                .cancelable(false)
                .build();
    }

    @Override
    protected void onResume() {
        super.onResume();
        //register the broadcast receivers for this activity.
        foundDeviceReceiver = FoundDeviceReceiver.register(this, this);
    }

    @Override
    protected void onPause() {
        super.onPause();
        //unregister the receivers.
        FoundDeviceReceiver.safeUnregister(this, foundDeviceReceiver);
    }

    /**
     * Helper method that populates the list with the bonded devices from this device.
     */
    private void populateList() {
        devices = new ArrayList<BluetoothDevice>();
        devices = getSimpleBluetooth().getBluetoothUtility().getPairedDevices();
        bdla = new BluetoothDeviceListAdapter(this,
                R.layout.devpaul_bluetooth_list_item_layout, devices);
        listView.setAdapter(bdla);
        listView.setOnItemClickListener(new AdapterView.OnItemClickListener() {
            @Override
            public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
                BluetoothDevice selectedDevice = bdla.getItem(i);
                if (checkDevicePaired(selectedDevice)) {
                    Intent data = new Intent();
                    data.putExtra(DEVICE_DIALOG_DEVICE_ADDRESS_EXTRA, selectedDevice.getAddress());
                    data.putExtra(DEVICE_DIALOG_DEVICE_EXTRA, selectedDevice);
                    setResult(RESULT_OK, data);
                    finish();
                } else {
                    getSimpleBluetooth().getBluetoothUtility().pairDevice(selectedDevice);
                }

            }
        });
    }

    @Override
    public SimpleBluetoothListener getSimpleBluetoothListener() {
        return new SimpleBluetoothListener() {
            @Override
            public void onDiscoveryStarted() {
                super.onDiscoveryStarted();
                if(progressDialog != null) {
                    progressDialog.show();
                }
            }

            @Override
            public void onDiscoveryFinished() {
                super.onDiscoveryFinished();
                if(progressDialog != null) {
                    if(progressDialog.isShowing()) {
                        progressDialog.dismiss();
                    }
                }
            }

            @Override
            public void onDevicePaired(BluetoothDevice device) {
                super.onDevicePaired(device);
            }

            @Override
            public void onDeviceUnpaired(BluetoothDevice device) {
                super.onDeviceUnpaired(device);
            }
        };
    }

    public boolean checkDevicePaired(BluetoothDevice device) {
        return getSimpleBluetooth().getBluetoothUtility().checkIfPaired(device);
    }

    @Override
    public void onBluetoothEnabled() {
        populateList();
    }

    @Override
    public void onDeviceFound(BluetoothDevice device) {
        bdla.add(device);
        bdla.notifyDataSetChanged();
    }


}
