using TMPro;
using UnityEngine;



public class FpsCounter : MonoBehaviour
{


	private TextMeshProUGUI _view;



	private void Start()
	{
		_view = GetComponent<TextMeshProUGUI>();
	}


	private void Update()
	{
		_view.text = $"{(int)(1.0f / Time.deltaTime)}";
	}


}
