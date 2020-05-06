// -*- mode: java; c-basic-offset: 2; -*-
// Copyright 2009-2011 Google, All Rights reserved
// Copyright 2011-2012 MIT, All rights reserved
// Released under the Apache License, Version 2.0
// http://www.apache.org/licenses/LICENSE-2.0

package com.gmail.at.moicjarod;

import com.google.appinventor.components.runtime.*;
import com.google.appinventor.components.runtime.util.RuntimeErrorAlert;
import com.google.appinventor.components.annotations.DesignerComponent;
import com.google.appinventor.components.annotations.DesignerProperty;
import com.google.appinventor.components.annotations.PropertyCategory;
import com.google.appinventor.components.annotations.SimpleEvent;
import com.google.appinventor.components.annotations.SimpleFunction;
import com.google.appinventor.components.annotations.SimpleObject;
import com.google.appinventor.components.annotations.SimpleProperty;
import com.google.appinventor.components.annotations.UsesLibraries;
import com.google.appinventor.components.annotations.UsesPermissions;
import com.google.appinventor.components.common.ComponentCategory;
import com.google.appinventor.components.common.PropertyTypeConstants;
import com.google.appinventor.components.runtime.util.AsynchUtil;
import com.google.appinventor.components.runtime.util.ErrorMessages;
import com.google.appinventor.components.runtime.util.YailList;
import com.google.appinventor.components.runtime.util.SdkLevel;

import com.google.appinventor.components.runtime.errors.YailRuntimeError;

import android.app.Activity;
import android.text.TextUtils;
import android.util.Log;
import android.os.StrictMode;

import java.io.*;
import java.net.*;


/**
 * Simple Client Socket
 * @author moicjarod@gmail.com (Jean-Rodolphe Letertre)
 * with the help of the work of lizlooney @ google.com (Liz Looney) and josmasflores @ gmail.com (Jose Dominguez)
 * the help of Alexey Brylevskiy for debugging
 * and the help of Hossein Amerkashi from AppyBuilder for compatibility with AppyBuilder
 */
 // The original code of this application was modified by Paolo Nardi to fit his App inventor project
 
@DesignerComponent(version = 4,
  description = "Non-visible component that provides client socket connectivity.",
  category = ComponentCategory.EXTENSION,
  nonVisible = true,
  iconName = "http://jr.letertre.free.fr/Projets/AIClientSocket/clientsocket.png")
  @SimpleObject(external = true)
  @UsesPermissions(permissionNames = "android.permission.INTERNET")


public class ClientSocketAI2Ext extends AndroidNonvisibleComponent implements Component
{
  private static final String LOG_TAG = "ClientSocketAI2Ext";

  private final Activity activity;

  // the socket object
  public Socket clientSocket = null;
  // the address to connect to
  private String serverAddress = "";
  // the port to connect to
  private String serverPort = "";
  // boolean that indicates the state of the connection, true = connected, false = not connected
  private boolean connectionState = false;

  InputStream inputStream = null; //Input stream object
  
  OutputStream outputStream = null;//Output stream object
 
  PrintStream pout = null; //Prinstream object
  
  

  /**
   * Creates a new Client Socket component.
   *
   * @param container the Form that this component is contained in.
   */
  public ClientSocketAI2Ext(ComponentContainer container)
  {
    super(container.$form());
    activity = container.$context();
    // compatibility with AppyBuilder (thx Hossein Amerkashi <kkashi01 [at] gmail [dot] com>)
    StrictMode.ThreadPolicy policy = new StrictMode.ThreadPolicy.Builder().permitAll().build();
    StrictMode.setThreadPolicy(policy);
  }

  /**
   * Method that returns the server's address.
   */
  @SimpleProperty(category = PropertyCategory.BEHAVIOR, description = "The address of the server the client will connect to.")
  public String ServerAddress()
  {
    return this.serverAddress;
  }

  /**
   * Method to specify the server's address
   */
  @DesignerProperty(editorType = PropertyTypeConstants.PROPERTY_TYPE_STRING)
  @SimpleProperty
  public void ServerAddress(String address)
  {
    this.serverAddress = address;
  }

  /**
   * Method that returns the server's port.
   */
  @SimpleProperty(category = PropertyCategory.BEHAVIOR, description = "The port of the server the client will connect to.")
  public String ServerPort()
  {
    return this.serverPort;
  }

  /**
   * Method to specify the server's port
   */
  @DesignerProperty(editorType = PropertyTypeConstants.PROPERTY_TYPE_STRING)
  @SimpleProperty
  public void ServerPort(String port)
  {
    this.serverPort = port;
  }

  /**
   * Method that returns the connection state
   */
  @SimpleProperty(category = PropertyCategory.BEHAVIOR, description = "The state of the connection - true = connected, false = disconnected")
  public boolean ConnectionState()
  {
    return this.connectionState;
  }

  
  /**
   * Creates the socket, connect to the server and launches the thread to receive data from server
   */
  @SimpleFunction(description = "Tries to connect to the server and launches the thread for receiving data (blocking until connected or failed)")
  public void Connect()
  {
    if (connectionState == true)
    {
      throw new YailRuntimeError("Connect error, socket connected yet, please disconnect before reconnect !", "Error");
    }
    try
    {
      // connecting the socket
      clientSocket = new Socket();
      clientSocket.connect(new InetSocketAddress(serverAddress, Integer.parseInt(serverPort)), 5000);
      connectionState = true;
	  outputStream = new BufferedOutputStream(clientSocket.getOutputStream());
      pout = new PrintStream(outputStream);
	
    }
    catch (SocketException e)
    {
      Log.e(LOG_TAG, "ERROR_CONNECT", e);
      throw new YailRuntimeError("Connect error" + e.getMessage(), "Error");
    }
    catch (Exception e)
    {
      connectionState = false;
      Log.e(LOG_TAG, "ERROR_CONNECT", e);
      throw new YailRuntimeError("Connect error (Socket Creation)" + e.getMessage(), "Error");
    }
  }

  /**
   * Send data through the socket to the server
   */
  @SimpleFunction(description = "Send data to the server")
  public void SendData(final String data)
  {
    
    if (connectionState == false)
    {
      throw new YailRuntimeError("Send error, socket not connected.", "Error");
    }
	
    // we then send asynchonously the data
    AsynchUtil.runAsynchronously(new Runnable()
    {
      @Override
      public void run()
      {
        try
        {
          pout.println(data);
		  pout.flush();
        }
        catch (Exception e)
        {
          Log.e(LOG_TAG, "ERROR_UNABLE_TO_SEND_DATA", e);
          throw new YailRuntimeError("Send Data", "Error");
        }
      }
    } );
  }

  /**
   * Close the socket
   */
  @SimpleFunction(description = "Disconnect to the server")
  public void Disconnect()
  {
	try {
    if (connectionState == true)
    {
       pout.println("end");
	   pout.flush();
	   outputStream.flush();
	   outputStream.flush();
	   pout.close();
	   outputStream.close();
	   clientSocket.close();
	   connectionState = false;
	   RemoteConnectionClosed();
       return;
	} else {
      throw new YailRuntimeError("Socket not connected, can't disconnect.", "Error");
  }
	}catch (SocketException e)
      {
        // modifications by axeley too :-)
        if(e.getMessage().indexOf("ENOTCONN") == -1)
        {
          Log.e(LOG_TAG, "ERROR_CONNECT", e);
          throw new YailRuntimeError("Disconnect" + e.getMessage(), "Error");
         }
         // if not connected, then just ignore the exception
      }
      catch (IOException e)
      {
        Log.e(LOG_TAG, "ERROR_CONNECT", e);
        throw new YailRuntimeError("Disconnect" + e.getMessage(), "Error");
      }
      catch (Exception e)
      {
        Log.e(LOG_TAG, "ERROR_CONNECT", e);
        throw new YailRuntimeError("Disconnect" + e.getMessage(), "Error");
      }
  }
  

  /**
   * Event indicating that the remote socket closed the connection
   *
   */
  @SimpleEvent
  public void RemoteConnectionClosed()
  {
    // invoke the application's "RemoteConnectionClosed" event handler.
    EventDispatcher.dispatchEvent(this, "RemoteConnectionClosed");
  }
}