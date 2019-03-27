using UnityEngine;
using Random = UnityEngine.Random;



public class GpuInstancing : MonoBehaviour
{


	#region Unity properties

	[SerializeField] private Transform _originalInstance;
	[SerializeField] private int _instanceAmount;
	[SerializeField, Range(0.001f, 1.0f)] private float _instanceScale;
	[SerializeField] private float _areaRadius;

	#endregion

	#region Private fields

	private bool _isToRespawn;

	#endregion


	private void OnValidate()
	{
		_areaRadius = Mathf.Max(0.1f, _areaRadius);
		_isToRespawn = _instanceAmount != transform.childCount;
	}


	private void Start()
	{
		Spawn();
	}


	private void Update()
	{
		if (_isToRespawn)
		{
			Despawn();
			Spawn();

			_isToRespawn = false;
		}
		else
		{
			foreach (Transform child in transform)
			{
				UpdateScaleAndPosition(child);
			}
		}
	}


	private void Despawn()
	{
		foreach (Transform child in transform)
		{
			Destroy(child.gameObject);
		}
	}


	private void Spawn()
	{
		MaterialPropertyBlock materialPropertyBlock = new MaterialPropertyBlock();

		for (int i = 0; i < _instanceAmount; i++)
		{
			Transform instance = Instantiate(_originalInstance, transform, true);
			instance.localRotation = Quaternion.Euler(Random.insideUnitSphere); // just keep the a rand pos in a local rotation to use it later

			Color color = Color.Lerp(new Color(Random.value, Random.value, Random.value), Color.white, 0.3f); // just do it a bit white

			materialPropertyBlock.SetColor("_Color", color);
			materialPropertyBlock.SetFloat("_Metallic", Random.value);
			materialPropertyBlock.SetFloat("_Glossiness", Random.value);
			instance.GetComponent<MeshRenderer>().SetPropertyBlock(materialPropertyBlock);
		}
	}


	private void UpdateScaleAndPosition(Transform tran)
	{
		Vector3 newPos = ConvertWithNegativeAngles(tran.localRotation.eulerAngles);

		tran.localPosition = Vector3.Lerp(tran.localPosition, newPos * _areaRadius, 0.5f);
		tran.localScale = Vector3.Lerp(tran.localScale, Vector3.one * _instanceScale, 0.1f);
	}


	private Vector3 ConvertWithNegativeAngles(Vector3 euler)
	{
		euler.x = euler.x > 180 ? euler.x - 360 : euler.x;
		euler.y = euler.y > 180 ? euler.y - 360 : euler.y;
		euler.z = euler.z > 180 ? euler.z - 360 : euler.z;

		return euler;
	}


}
