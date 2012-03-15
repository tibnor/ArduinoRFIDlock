package no.doorlock;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.URI;
import java.net.URISyntaxException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

import org.apache.http.HttpEntity;
import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.Activity;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.Button;
import android.widget.Toast;

import com.google.zxing.integration.android.IntentIntegrator;

public class DoorlockActivity extends Activity {
	static final String TAG = "no.doorlock";
	public static final String PREFS_STORAGE_NAME = "auth";
	public static final String PREFS_IP = "ip";
	public static final String PREFS_SECRET = "secret";
	public static final String PREFS_ID = "id";
	public static final String PREFS_NAME = "name";

	/** Called when the activity is first created. */
	@Override
	public void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.main);

		Button toggleDoor = (Button) findViewById(R.id.button1);
		toggleDoor.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				SharedPreferences settings = getSharedPreferences(PREFS_STORAGE_NAME, 0);
				String ip = settings.getString(PREFS_IP, ""); //"http://192.168.1.110/";
				Log.d(TAG, "buttonclick");
				String id = settings.getString(PREFS_ID, "");

				
				URI url;
				try {
					url = new URI(ip + "getWord?_id="+id);
				} catch (final URISyntaxException e) {
					// Should not happen
					e.printStackTrace();
					return;
				}
				Log.v(TAG, "url: " + url.toString());

				HttpClient client = new DefaultHttpClient();
				HttpGet request = new HttpGet(url);
				String word = null;
				try {
					final HttpResponse response = client.execute(request);
					final HttpEntity r_entity = response.getEntity();

					final String xmlString = EntityUtils.toString(r_entity);
					final JSONObject val = new JSONObject(xmlString);
					word = val.getString("word");


				} catch (final Exception e) {
					e.printStackTrace();
					Toast toast = Toast.makeText(DoorlockActivity.this,
							"Fikk ikke kontakt med kortleseren, har du huske å gi apekatten mat?", Toast.LENGTH_LONG);
						toast.show();
						return;
				}

				String secret = settings.getString(PREFS_SECRET,"");
				String token = null;
				try {
					token = SHA1(secret + word);
				} catch (NoSuchAlgorithmException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				} catch (UnsupportedEncodingException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
				try {
					url = new URI(ip + "openDoor?_id="+id+"&token=" + token);
				} catch (final URISyntaxException e) {
					// Should not happen
					e.printStackTrace();
					return;
				}
				Log.v(TAG, "url: " + url.toString());

				client = new DefaultHttpClient();
				request = new HttpGet(url);
				String message = "Fikk ikke kontakt med kortleseren, har du huske å gi apekatten mat?";
				try {
					final HttpResponse response = client.execute(request);
					
					final HttpEntity r_entity = response.getEntity();
					final String xmlString = EntityUtils.toString(r_entity);
					final JSONObject val = new JSONObject(xmlString);
					// Log.v(TAG, "hash:" + SHA1(password +
					// key.toString()));
					Integer status =  val.getInt("status");
					
					switch (status) {
					case 200:
						if (1==val.getInt("open"))
							message = "Apekatten åpner nå låsen";
						else
							message = "Apekatten låser nå døren";
						break;
					case 403:
						message = "Fikk kontakt med apekatten, men han nekter å slippe deg inn";
					}

					// Commit the edits!

				} catch (final IOException e) {
					// throw new NetworkErrorException(e);
				} catch (final JSONException e) {
					e.printStackTrace();
				}
				Toast toast = Toast.makeText(DoorlockActivity.this,
						message, Toast.LENGTH_SHORT);
				toast.show();
			}
		});

		Button scanQR = (Button) findViewById(R.id.scanqr);
		scanQR.setOnClickListener(new OnClickListener() {

			@Override
			public void onClick(View v) {
				IntentIntegrator integrator = new IntentIntegrator(
						DoorlockActivity.this);
				integrator.initiateScan();

			}

		});
	}

	private static String convertToHex(byte[] data) {
		StringBuffer buf = new StringBuffer();
		for (int i = 0; i < data.length; i++) {
			int halfbyte = (data[i] >>> 4) & 0x0F;
			int two_halfs = 0;
			do {
				if ((0 <= halfbyte) && (halfbyte <= 9))
					buf.append((char) ('0' + halfbyte));
				else
					buf.append((char) ('a' + (halfbyte - 10)));
				halfbyte = data[i] & 0x0F;
			} while (two_halfs++ < 1);
		}
		return buf.toString();
	}

	public static String SHA1(String text) throws NoSuchAlgorithmException,
			UnsupportedEncodingException {
		MessageDigest md;
		md = MessageDigest.getInstance("SHA-1");
		byte[] sha1hash = new byte[40];
		md.update(text.getBytes("iso-8859-1"), 0, text.length());
		sha1hash = md.digest();
		return convertToHex(sha1hash);
	}

	public void onActivityResult(int requestCode, int resultCode, Intent intent) {
		String scanResult = IntentIntegrator.parseActivityResult(requestCode,
				resultCode, intent);
		if (scanResult != null) {
			Log.v(TAG, "qrcode:" + scanResult);
			String message = "fail";
			try {
				JSONObject val = new JSONObject(scanResult);
				String id = val.getString("id");
				String secret = val.getString("secret");
				String ip = val.getString("url");
				String name = val.getString("name");
				Log.v(TAG, "secret:" + secret +" IP:"+ip);
				SharedPreferences settings = getSharedPreferences(PREFS_STORAGE_NAME, 0);
				SharedPreferences.Editor editor = settings.edit();
				editor.putString(PREFS_ID, id);
				editor.putString(PREFS_SECRET, secret);
				editor.putString(PREFS_IP, ip);
				editor.putString(PREFS_NAME, name);
				editor.commit();
				message = "success";
			} catch (JSONException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			Toast toast = Toast.makeText(DoorlockActivity.this,
					message, Toast.LENGTH_SHORT);
			toast.show();

		}
		// else continue with any other code you need in the method
	}
}