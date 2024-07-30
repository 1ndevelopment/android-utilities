#!/system/bin/sh

#pkg update && pkg upgrade
#pkg install aapt apksigner dx ecj findutils git

APP_NAME=com.indev.superedit
WORKSPACE=com.indev.superedit

silence() { "$@" >/dev/null 2>&1; }

silence su -c "pm uninstall $APP_NAME"
silence su -c "rm -r $WORKSPACE $APP_NAME.apk"
mkdir -p $WORKSPACE/src/com/indev/superedit
mkdir -p $WORKSPACE/res/layout
cd $WORKSPACE

cat << EOF > AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$APP_NAME">
    <uses-permission android:name="android.permission.ACCESS_SUPERUSER" />
    <application
        android:label="Super Edit"
        android:theme="@android:style/Theme.DeviceDefault">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat << EOF > src/com/indev/superedit/MainActivity.java
package $APP_NAME;

import android.app.Activity;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.InputStreamReader;

public class MainActivity extends Activity {
    private EditText commandInput;
    private Button executeButton;
    private TextView outputText;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        commandInput = findViewById(R.id.commandInput);
        executeButton = findViewById(R.id.executeButton);
        outputText = findViewById(R.id.outputText);

        executeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String command = commandInput.getText().toString();
                executeRootCommand(command);
            }
        });
    }

    private void executeRootCommand(String command) {
        try {
            Process process = Runtime.getRuntime().exec("su");
            DataOutputStream os = new DataOutputStream(process.getOutputStream());
            os.writeBytes(command + "\n");
            os.writeBytes("exit\n");
            os.flush();

            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            StringBuilder output = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                output.append(line).append("\n");
            }

            outputText.setText(output.toString());
        } catch (Exception e) {
            outputText.setText("Error: " + e.getMessage());
        }
    }
}
EOF


cat << EOF > res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:padding="16dp">

    <EditText
        android:id="@+id/commandInput"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        android:hint="Enter root command" />

    <Button
        android:id="@+id/executeButton"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="Execute" />

    <ScrollView
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:layout_marginTop="16dp">

        <TextView
            android:id="@+id/outputText"
            android:layout_width="match_parent"
            android:layout_height="wrap_content" />
    </ScrollView>

</LinearLayout>
EOF

build_apk() {
  PKGNAME="$(grep -o "package=.*" AndroidManifest.xml | cut -d\" -f2)"

  printf "%s\\n" "Beginning build"
  [ -d assets ] || mkdir assets
  [ -d res ] || mkdir res
  mkdir -p output
  mkdir -p gen
  mkdir -p obj


  printf "%s\\n" "aapt: started..."
  aapt package -f -m \
          -M "AndroidManifest.xml" \
       	  -J "gen" \
       	  -S "res"
  printf "%s\\n\\n" "aapt: done"


  printf "%s\\n" "ecj: begun..."
  for JAVAFILE in $(find . -type f -name "*.java")
  do
       	  JAVAFILES="$JAVAFILES $JAVAFILE"
  done
  ecj -d obj -sourcepath . $JAVAFILES
  printf "%s\\n\\n" "ecj: done"


  printf "%s\\n" "dx: started..."
  dx --dex --output=output/classes.dex obj
  printf "%s\\n\\n" "dx: done"


  printf "%s\\n" "Making $PKGNAME.apk..."
  aapt package -f \
       	  --min-sdk-version 1 \
       	  --target-sdk-version 23 \
       	  -M AndroidManifest.xml \
       	  -S res \
       	  -A assets \
       	  -F output/"$PKGNAME.unsigned.apk"


  printf "\n%s\\n" "Adding classes.dex to $PKGNAME.apk..."
  cd output
  aapt add -f "$PKGNAME.unsigned.apk" classes.dex || { cd ..; }

  printf "\n%s" "Signing $PKGNAME.unsigned.apk: "
  rm -f ~/.android/debug.keystore
  mkdir -p ~/.android
  keytool -genkey -v -keystore ~/.android/debug.keystore -storepass android -alias androiddebugkey -keypass android -dname "CN=Android Debug,O=Android,C=US" -keyalg RSA -keysize 2048 -validity 10000
  zipalign -p 4 $PKGNAME.unsigned.apk $PKGNAME.unsigned.aligned.apk
  apksigner sign --ks-key-alias androiddebugkey --ks ~/.android/debug.keystore --ks-pass pass:android $PKGNAME.unsigned.aligned.apk
  mv $PKGNAME.unsigned.aligned.apk $PKGNAME.apk
  printf "%s\\n" "DONE"

  printf "\n%s" "Verifying $PKGNAME.apk: "
  unzip -l $PKGNAME.unsigned.apk
  zipalign -c 4 $PKGNAME.apk
  apksigner verify $PKGNAME.apk
  printf "%s\\n" "DONE"

  mv $PKGNAME.apk ../..

  printf "\n%s" "Installing $PKGNAME.apk: "
  cd ../..
  su -c "pm install $PKGNAME.apk"
}

build_apk
