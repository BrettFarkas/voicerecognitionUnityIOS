//This is SpeechController.cs located in the scripts folder in Unity.  The swift plugin file gets the voice to text, and if it recognizes a certain phrase it is looking for it sends a message here.  In this case if the swift file heard the right phrase it will send the message "showMagician" which will make the magician object appear.  (look at the OnSpeechRecognized method below).  This script is attached to an empty SpeechManager object.  This script turns off the 'magician1' object to begin with, and after swift sends a message 'showMagician' it makes the magician1 object appear.  You can use else/if statements in the OnSpeechRecognized method to add more ways to receive messages from the swift plugin file and do more things in the game.

using UnityEngine;
using System.Runtime.InteropServices;

public class SpeechController : MonoBehaviour
{
    [DllImport("__Internal")]
    private static extern void startListening();

    public GameObject magician1;

    void Start()
    {
        magician1.SetActive(false); // Hide magician1 at start
        StartListening();  // Start speech recognition
    }

    public void StartListening()
    {
        #if UNITY_IOS && !UNITY_EDITOR
            startListening();
        #endif
    }

    public void OnSpeechRecognized(string message)
    {
        Debug.Log("Unity Received: " + message);
        if (message == "showMagician")
        {
            magician1.SetActive(true);
        }
    }
}
